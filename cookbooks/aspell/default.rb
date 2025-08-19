include_recipe "dependency.rb"

case node[:platform]
when "arch"
  package "aspell"
  package "aspell-en"
when "osx", "darwin"
  raise NotImplementedError
when "fedora", "redhat", "amazon"
  raise NotImplementedError
when "debian", "ubuntu", "mint"
  package "aspell"
  package "aspell-en"
when "opensuse"
  raise NotImplementedError
else
  raise NotImplementedError
end

file "#{node[:home]}/.aspell.conf" do
  action :create
  owner node[:user]
  group node[:group]

  content "lang en_US"
end

config_dir = node[:config_dir]

execute "aspell -d en dump master | aspell -l en expand > #{config_dir}/dictionary/my.dict" do
  user user
  cwd "#{config_dir}/dictionary"
  not_if "test -e #{config_dir}/dictionary/my.dict"
end
