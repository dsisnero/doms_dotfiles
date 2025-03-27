# Create a user-specific temporary directory to avoid permission issues
home = node[:home]
config_home = node[:config_home]

# Common XDG paths
git_config_dir = "#{config_home}/git"
git_hooks_dir = "#{git_config_dir}/hooks"

case node[:os]
when "windows"
  # Windows Git installation via Chocolatey
  chocolatey_package "git"
  chocolatey_package "mitamae"
  chocolatey_package "git-credential-manager-for-windows" do
    not_if { wsl? }
  end

  # Create config directory if it doesn't exist
  directory git_config_dir do
    user node[:user]
    recursive true
  end

when "linux"
  case node[:platform]
  when "debian", "ubuntu", "mint", "pop"
    package "software-properties-common"

    execute "add apt repository" do
      command <<-EOL
        add-apt-repository -y ppa:git-core/ppa
        apt update
      EOL

      not_if "ls /etc/apt/sources.list.d | grep git"
    end

    package "git"
    package "git-secrets" do
      not_if "which git-secrets"
    end
  when "fedora", "redhat", "amazon"
    # Existing fedora/redhat setup
  when "arch"
    package "git"
    package "git-flow"
  end
when "macos"
  package "git"
end

# Only proceed with Unix-style config if not on Windows or if in WSL
unless node[:os] == "windows" && !wsl?
  # Ensure parent git directory exists
  directory git_config_dir do
    user node[:user]
    group node[:group]
    mode "755"
  end

  directory git_hooks_dir do
    user node[:user]
    group node[:group]
    mode "0755"
  end

  # Main .gitconfig with platform-specific includes
  template "#{git_config_dir}/config" do
    source "templates/git/gitconfig.erb"
    owner node[:user]
    group node[:group]
    mode "644"
    variables(
      platform: node[:platform],
      os: node[:os] || "linux", # Add explicit default
      is_wsl: node[:is_wsl],
      config_dir: git_config_dir,
      hooks_dir: git_hooks_dir
    )
  end

  # Platform-specific config directory
  directory "#{git_config_dir}/platforms" do
    user node[:user]
    group node[:group]
    mode "755"
  end

  # Common git configuration
  template "#{git_config_dir}/config.common" do
    source "templates/git/common_config.erb"
    owner node[:user]
    group node[:group]
    mode "644"
  end

  # Platform-specific templates
  %w[darwin linux windows wsl].each do |platform|
    template "#{git_config_dir}/platforms/#{platform}" do
      source "templates/git/platforms/#{platform}.erb"
      owner node[:user]
      group node[:group]
      mode "644"
    end
  end

  # Install pre-commit hook
  template "#{git_hooks_dir}/pre-commit" do
    source "templates/git/hooks/pre-commit.erb"
    mode "755"
    owner node[:user]
    group node[:group]
    variables(
      user: node[:user]
    )
  end

  # Install commit-msg hook
  template "#{git_hooks_dir}/commit-msg" do
    source "templates/git/hooks/commit-msg.erb"
    mode "755"
    owner node[:user]
    group node[:group]
    variables(
      user: node[:user]
    )
  end

  # Configure global hooks path
  execute "git config --global core.hooksPath '#{git_hooks_dir}'" do
    user node[:user]
    not_if "git config --global core.hooksPath | grep -q '#{git_hooks_dir}'"
  end
end

# Windows-specific Git configuration (when not in WSL)
if node[:os] == "windows" && !wsl?
  # Windows Git configuration
  template "#{home}/.gitconfig" do
    source "templates/git/windows_gitconfig.erb"
    variables(
      user_name: node[:git_user_name] || "Your Name",
      user_email: node[:git_user_email] || "your.email@example.com",
      credential_helper: "manager-core",
      xdg_config: git_config_dir
    )
  end

  # Set Git to use LF line endings even on Windows
  execute "Configure Git line endings" do
    command "git config --global core.autocrlf false"
    user node[:user]
  end

  # Set Git to use UTF-8 for commit messages and file names
  execute "Configure Git encoding" do
    command "git config --global core.quotepath off"
    user node[:user]
  end
end
