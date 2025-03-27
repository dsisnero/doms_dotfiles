class Specinfra::Command::Pop < Specinfra::Command::Ubuntu
end
node[:family] = "ubuntu" if node[:platform] == "pop"

include_recipe "node_supplement.rb"
puts "node info: #{node.mash.to_yaml}"
MItamae.logger.info "Node Info:\n#{node.inspect}"
::MItamae::RecipeContext.class_eval do
  # Helper methods for platform detection
  def windows?
    node[:is_windows]
  end

  def wsl?
    node[:is_wsl]
  end

  # node hashのパラメータで必須のものを初期設定する。
  def init_node
    # Ensure os is always defined
    node.reverse_merge!(
      os: node[:os] || 'linux' # Default fallback
    )
    
    user = ENV["SUDO_USER"] || ENV["USER"]
    if node[:os] == "windows"
      # Windows-specific defaults
      home = node[:home] # Already normalized in node_supplement.rb
      group = 'Users'
      user_bin = "#{home}/AppData/Local/Microsoft/WindowsApps"
    else
      # Unix-based systems
      case node[:platform]
      when "osx", "darwin"
        home = ENV["HOME"]
        group = "staff"
      when "arch"
        home = `cat /etc/passwd | grep '^#{user}:' | awk -F: '!/nologin/{print $(NF-1)}'`.strip
        group = user
      when "pop"
        home = `cat /etc/passwd | grep '^#{user}:' | awk -F: '!/nologin/{print $(NF-1)}'`.strip
        group = user
      else
        home = `cat /etc/passwd | grep '^#{user}:' | awk -F: '!/nologin/{print $(NF-1)}'`.strip
        group = user
      end      
      user_bin = "#{home}/.local/bin"
    end
    
    # Unified XDG_CONFIG_HOME handling across all platforms
    config_home = ENV.fetch("XDG_CONFIG_HOME") do
      if node[:is_windows]
        "#{home}/AppData/Roaming"
      else
        "#{home}/.config"
      end
    end

    # Unified XDG_DATA_HOME handling
    data_home = ENV.fetch("XDG_DATA_HOME") do
      if node[:is_windows]
        "#{home}/AppData/Local"
      else
        "#{home}/.local/share"
      end
    end
    repos = if node[:is_windows]

       "d:/repos"
    else
     "#{home}/repos"
    end
    dotfile_repos = "#{repos}/github.com/dsisnero/doms_dotfiles"

    node.reverse_merge!(
      user: user,
      default_user: user,
      group: group,
      home: home,
      config_home: config_home,
      data_home: data_home,
      cache_home: ENV.fetch("XDG_CACHE_HOME") { "#{home}/.cache" },
      user_bin: user_bin,
      repos: repos,
      dotfile_repos: dotfile_repos
    )
  end

  def update_package
    case node[:os]
    when "windows"
      execute "choco upgrade chocolatey -y" do
        only_if "where choco"
      end
    when "linux"
      case node[:platform]
      when "arch"
        execute "yay -Syy"
      when "fedora", "redhat", "amazon"
        # execute 'yum update -y' # '区別なし'
      when "debian", "ubuntu", "mint", "pop"
        execute "apt update -y"
      when "opensuse"
        MItamae.logger.debug("need package manager for opensuse")
      end
    when "macos"
      execute "brew update"
    end
  end

  def upgrade_package
    case node[:os]
    when "windows"
      execute "choco upgrade all -y" do
        only_if "where choco"
      end
    when "linux"
      case node[:platform]
      when "arch"
        execute "yay -Syu --noconfirm"
      when "fedora", "redhat", "amazon"
        execute "yum update -y" # 区別なし
      when "debian", "ubuntu", "mint", "pop"
        execute "apt upgrade -y"
      when "opensuse"
        MItamae.logger.debug("need package manager for opensuse")
      end
    when "macos"
      execute "brew upgrade"
    end
  end

  def include_cookbook(name)
    root_dir = File.expand_path("../..", __FILE__)
    include_recipe File.join(root_dir, "cookbooks", name, "default")
  end

  def include_role(name)
    root_dir = File.expand_path("../..", __FILE__)
    include_recipe File.join(root_dir, "roles", name, "default")
  end

  def has_package?(name)
    result = run_command("dpkg-query -f '${Status}' -W #{name.shellescape} | grep -E '^(install|hold) ok installed$'",
      error: false)
    result.exit_status == 0
  end

  def sudo(user)
    if node[:is_windows]
      # Windows doesn't have sudo, but we could use runas or similar
      ""
    elsif node[:platform] == "darwin" || node[:platform] == "osx"
      ""
    else
      "sudo -u #{user} -i "
    end
  end

  def run_as(user, cmd)
    if node[:is_windows]
      # Use PowerShell to run as different user if needed
      "powershell -Command \"Start-Process -FilePath 'cmd' -ArgumentList '/c #{cmd.gsub('"', '\"')}' -Verb RunAs\""
    elsif node[:platform] == "darwin" || node[:platform] == "osx"
      cmd
    else
      "su - #{user} -c \"cd ${PWD} && SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock #{cmd}\""
    end
  end

  def github_versions(repo)
    require "net/http"
    require "json"

    uri = URI("https://api.github.com/repos/#{repo}/tags")
    response = Net::HTTP.get(uri)
    tags = JSON.parse(response)
    tags.map { |tag| tag["name"] }
  end
end

::MItamae::ResourceContext.class_eval do
  def sudo(user)
    if node[:is_windows]
      ""
    elsif node[:platform] == "darwin" || node[:platform] == "osx"
      ""
    else
      "sudo -u #{user} -i "
    end
  end

  def run_as(user, cmd)
    if node[:is_windows]
      "powershell -Command \"Start-Process -FilePath 'cmd' -ArgumentList '/c #{cmd.gsub('"', '\"')}' -Verb RunAs\""
    elsif node[:platform] == "darwin" || node[:platform] == "osx"
      cmd
    else
      "su - #{user} -c \"cd ${PWD} && #{cmd}\""
    end
  end
end

# dotfileリポジトリ内へのシンボリックリンク設定
define :dotfile, source: nil, user: nil do
  dst = File.join(node[:config_home], params[:name])
  src = params[:source].nil? ? File.join(node[:dotfile_repos], "config", params[:name]) : params[:source]
  user = params[:user].nil? ? node[:user] : params[:user]
  # puts "dst: #{dst}"
  # puts "src: #{src}"

  if node[:is_windows]
    execute "Create symlink for #{params[:name]}" do
      command <<-PS1
      $target = "#{src.gsub('/', '\\')}"
      $link = "#{dst.gsub('/', '\\')}"
      if (Test-Path $link) { Remove-Item $link -Force -Recurse }
      New-Item -ItemType Junction -Path $link -Target $target
      PS1
      interpreter "powershell"
      user user
      not_if "powershell -Command \"if (Test-Path -Path '#{dst.gsub('/', '\\')}') { exit 0 } else { exit 1 }\""
    end
  else
    execute "ln -s #{src} #{dst}" do
      user user
      not_if "test -L #{dst}"
    end
  end
end

define :get_repo, build: nil do
  reponame = params[:name]
  user = params[:user].nil? ? ENV["SUDO_USER"] || ENV["USER"] : node[:user]
  home = node[:home]

  # Parse repository URL format
  repo_url = if reponame.include?("://") || reponame.include?("@")
               reponame # Already a full URL
             else
               "https://github.com/#{reponame}.git"
             end

  # Extract proper ghq path from URL
  cloned_dir = "#{home}/repos/#{repo_url.split(%r{[:/]})[1..-1].join('/').gsub(/\.git$/, '')}"

  execute "get_repo #{reponame}" do
    command "SSH_AUTH_SOCK=#{home}/.ssh/agent.sock mise exec -- ghq get -p '#{repo_url}'"
    user user
    not_if "test -d #{cloned_dir}"
  end

  unless params[:build].nil?
    version_check = if params[:version_cmd] && params[:version_str]
                      " && #{params[:version_cmd]} | grep -q '#{params[:version_str]}'"
                    else
                      ""
                    end

    execute "build #{reponame}" do
      command "cd #{cloned_dir} && #{params[:build]}"
      user user
      not_if "test -d #{cloned_dir}/target#{version_check}"
    end
  end
end

# go_get definition moved to cookbooks/go/default.rb

# githubから直接バイナリを取得してインストール
define :get_bin_github_release, version: nil, version_cmd: nil, version_str: nil, release_artifact_url: nil do
  target_name = params[:name]
  version = params[:version]

  version = params[:version]
  version_cmd = params[:version_cmd]
  version_str = params[:version_str]
  release_url = params[:release_artifact_url]

  execute "install #{target_name}" do
    command <<-EOCMD
    WORKDIR=work_#{version}

    cur=$(pwd) mkdir -p ${WORKDIR} cd ${WORKDIR} wget #{release_url} -O #{target_name} install #{target_name} /usr/local/bin/#{target_name} cd ${cur}
    rm -rf ${WORKDIR}
    EOCMD

    not_if "test -e /usr/local/bin/#{target_name} && test \"$(#{version_cmd})\" = \"#{version_str}\""
  end
end

define :github_binary, version: nil, repository: nil, archive: nil,
  binary_path: nil, version_cmd: nil, version_str: nil do
  cmd = params[:name]
  bin_path = "#{node[:user_bin]}/#{cmd}"
  params[:binary_path]
  archive = params[:archive]
  params[:version_cmd]
  params[:version_str]
  user = node[:user]
  test_cmd = "test -f #{bin_path}"
  # add version test test_cmd
  url = "https://github.com/#{params[:repository]}/releases/download/#{params[:version]}/#{archive}"

  if archive.end_with?(".zip")
    package "unzip" do
      not_if "which unzip"
    end
    extract = "unzip -o"
  elsif archive.end_with?(".tar.gz")
    extract = "tar xvzf"
  elsif archive.end_with?(".appimage")
    extract = "ls "
    params[:binary_path] = archive
    url = "https://github.com/#{params[:repository]}/releases/latest/download/#{archive}"
  else
    raise "unexpected ext archive: #{archive}"
  end

  directory node[:user_bin] do
    owner node[:user]
  end

  execute "curl -fSL -o /tmp/#{archive} #{url}" do
    not_if "test -f #{bin_path}"
  end

  execute "#{extract} /tmp/#{archive}" do
    not_if "test -f #{bin_path}"
    cwd "/tmp"
  end
  execute "mv /tmp/#{params[:binary_path] || cmd} #{bin_path} && chmod +x #{bin_path} && chown #{user}:#{user} #{bin_path}" do
    not_if test_cmd.to_s
  end
end

define :yay do
  name = params[:name]

  execute "yay -S --noconfirm #{name}" do
    user node[:user]
    not_if "yay -Q #{name}"
  end
end

define :install_font do
  name = params[:name]
  # typename = File.extname(name) == 'otf' ? 'OTF' : 'TTF'
  install_path = "~/.local/share/fonts"

  directory install_path
  execute "cp #{name} #{install_path}"
end

# Chocolatey package management for Windows
define :chocolatey_package, version: nil do
  package_name = params[:name]
  version = params[:version]

  execute "Install #{package_name} via Chocolatey" do
    command "choco install #{package_name} #{version ? "--version=#{version}" : ""} -y"
    not_if "choco list --local-only #{package_name} | findstr /C:\"#{package_name} \""
    only_if { windows? }
  end
end

init_node
