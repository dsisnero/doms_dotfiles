include_recipe "dependency.rb"

home = node[:home]
user = node[:user]
group = node[:group]

node.reverse_merge!({
  mysql: {
    major_version: 5,
    minor_version: 7,
    root_password: "D12uM3m4y+"
  }
})

major_version = node[:mysql][:major_version]
minor_version = node[:mysql][:minor_version]

# cf) https://github.com/k0kubun/itamae-plugin-recipe-rbenv/blob/master/lib/itamae/plugin/recipe/rbenv/dependency.rb
case node[:platform]
when "debian", "ubuntu", "mint"
  package "mysql-server"
  package "libmariadb-dev"

  if node[:is_wsl]
    execute "service mysql stop"

    # file "#{node[:home]}/.bashrc" do
    #   action [:edit]
    #   block do |content|
    #     content.gsub!('sudo service mysql start', '')
    #     content << 'sudo service mysql start'
    #   end
    # end
  else
    service "mysql" do
      action %i[start enable]
    end
  end

when "fedora"
  # cf) https://dev.mysql.com/downloads/repo/yum/
  package_name = "mysql#{major_version}#{minor_version}-community-release-fc27-10"
  package "https://dev.mysql.com/get/#{package_name}.noarch.rpm" do
    not_if "rpm -q #{package_name}"
  end

  package "mysql-community-server"
  package "mysql-community-devel"

when "redhat", "amazon"
  if node["platform_version"].to_i >= 7
    execute "remove old mariadb" do
      command "yum remove -y mariadb-libs"
      not_if 'test $(rpm -qa | grep maria | wc -l) == "0"'
    end

    execute "yum localinstall -y http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm"

  else
    package_name = "mysql#{major_version}#{minor_version}-community-release-el6-11"
    package "https://dev.mysql.com/get/#{package_name}.noarch.rpm" do
      not_if "rpm -q #{package_name}"
    end
  end

  package "mysql-community-server"
  package "mysql-community-devel"

  unless node[:is_wsl]
    service "mysqld" do
      action %i[start enable]
    end
  end

when "osx", "darwin"
when "arch"
  package "mysql"

  execute "mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql" do
    not_if { File.directory? "/var/lib/mysql/mysql" }
  end
  # execute 'mysql_secure_installation'

  unless node[:is_wsl]
    service "mysqld" do
      action %i[start enable]
    end
  end
when "opensuse"
end

# cf) https://qiita.com/kotanbo/items/263841bae08044676c83
# MySQL初期設定
new_password = node[:mysql][:root_password]
mysql_state_dir = "#{home}/.cache/mitamae/mysql"
mysql_no_password_init_marker = "#{mysql_state_dir}/no_password_init_done"

directory mysql_state_dir do
  owner user
  group group
  mode "700"
end

mysql_root_with_new_password = run_command("mysql -u root -p'#{new_password}' -e 'show databases' 2>/dev/null | grep -q information_schema", error: false).success?
mysql_root_without_password = run_command("mysql -u root -e 'show databases' 2>/dev/null | grep -q information_schema", error: false).success?

# If root already uses the configured password, mark init as complete so guard checks do not run every converge.
file mysql_no_password_init_marker do
  owner user
  group group
  mode "600"
  content "done\n"
  only_if { mysql_root_with_new_password }
end

execute "mark mysql no password init done" do
  command "touch #{mysql_no_password_init_marker} && chown #{user}:#{group} #{mysql_no_password_init_marker} && chmod 600 #{mysql_no_password_init_marker}"
  action :nothing
end

# password空の場合
# MItamae.logger.error "new password: #{new_password}"
if mysql_root_without_password && !File.exist?(mysql_no_password_init_marker)
  execute "initialize on no password" do
    user "root"

    command <<-EOL
      set -eu
      mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
      mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1');"
      mysql -u root -e "DROP DATABASE IF EXISTS test;"
      mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
      mysql -u root -e "FLUSH PRIVILEGES;"
      mysqladmin password #{new_password} -u root
    EOL
    notifies :run, "execute[mark mysql no password init done]", :immediately
  end
end

# passwordが初期値の場合
tmp_password_cmd = %(grep "A temporary password is generated" /var/log/mysqld.log | sed -s 's/.*root@localhost: //')
mysql_temp_password_needs_rotation = run_command(%(test -e /var/log/mysqld.log && mysql -uroot -p"$(#{tmp_password_cmd})" -e 'show databases' 2>/dev/null | grep -Eq 'connect-expired-password|information_schema'), error: false).success?
# MItamae.logger.error "password change: $(#{tmp_password_cmd}) -> #{new_password}"
if mysql_temp_password_needs_rotation && !mysql_root_with_new_password
  execute "mysql_secure_installation temp password" do
    user "root"

    command <<-EOL
          mysqladmin -uroot -p"$(#{tmp_password_cmd})" password '#{new_password}'
          mysql_secure_installation -p'#{new_password}' -D
    EOL
  end
end

execute "mysql user add for auth_socket" do
  only_if "mysql -u root -p#{new_password} -e 'show databases' 2>/dev/null | grep -q information_schema"
  not_if "mysql -u root -p#{new_password} -e \"SELECT User FROM mysql.user WHERE User='#{node[:user]}' AND Host='localhost' LIMIT 1\" 2>/dev/null | grep -q '#{node[:user]}'"

  command <<-EOL
    set -eu
    mysql -uroot -p'#{new_password}' -e "CREATE USER IF NOT EXISTS '#{node[:user]}'@localhost IDENTIFIED BY '#{new_password}';"
    #mysql -uroot -p'#{new_password}' -e "CREATE USER IF NOT EXISTS '#{node[:user]}'@localhost IDENTIFIED VIA unix_socket;"
    mysql -uroot -p'#{new_password}' -e "GRANT ALL ON *.* TO '#{node[:user]}'@'localhost';"
  EOL
end

%w[pip pip3].each do |pip|
  execute "mise exec -- pip install mycli" do
    not_if "mise exec -- which mycli"
    only_if "mise exec -- which #{pip}>/dev/null"
  end
end
