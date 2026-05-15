# Create a user-specific temporary directory to avoid permission issues
home = node[:home]
config_home = node[:config_home]
os = node[:os] || node[:platform]

# Common XDG paths
git_config_dir = "#{config_home}/git"
git_hooks_dir = "#{git_config_dir}/hooks"

case os
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
when "macos", "darwin", "osx"
  package "git"
end

# Only proceed with Unix-style config if not on Windows or if in WSL
unless os == "windows" && !wsl?
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

  # Map platform to template name
  platform_template = case node[:platform]
  when "debian", "ubuntu", "mint", "pop", "fedora", "redhat", "amazon", "arch", "linux"
    "linux"
  when "darwin", "osx", "macos"
    # Check if we're on ExFAT filesystem (common with external drives on macOS)
    begin
      # Try to detect ExFAT filesystem for current working directory
      current_dir = Dir.pwd
      fs_info = run_command("diskutil info '#{current_dir}' 2>/dev/null | grep 'File System Personality' | awk -F': ' '{print $2}'", error: false)

      if fs_info.success? && !fs_info.stdout.strip.empty?
        fs_type = fs_info.stdout.strip.downcase
        MItamae.logger.info "Detected filesystem: #{fs_type} for #{current_dir}"

        if fs_type.include?("exfat")
          MItamae.logger.info "Using ExFAT-specific git configuration for macOS"
          "darwin_exfat"
        else
          "darwin"
        end
      else
        # Fallback: check home directory filesystem
        home_fs_info = run_command("diskutil info '#{node[:home]}' 2>/dev/null | grep 'File System Personality' | awk -F': ' '{print $2}'", error: false)

        if home_fs_info.success? && !home_fs_info.stdout.strip.empty?
          home_fs_type = home_fs_info.stdout.strip.downcase
          MItamae.logger.info "Detected home filesystem: #{home_fs_type}"

          if home_fs_type.include?("exfat")
            MItamae.logger.info "Using ExFAT-specific git configuration for macOS (home directory)"
            "darwin_exfat"
          else
            "darwin"
          end
        else
          "darwin" # default macOS configuration
        end
      end
    rescue => e
      MItamae.logger.warn "Could not detect filesystem type: #{e.message}. Using default macOS configuration."
      "darwin"
    end
  when "windows"
    "windows"
  else
    "linux" # default
  end

  # Main .gitconfig with platform-specific includes
  template "#{git_config_dir}/config" do
    source "templates/git/gitconfig.erb"
    owner node[:user]
    group node[:group]
    mode "644"
    variables(
      platform: platform_template,
      os: os || "linux", # Add explicit default
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
    variables(
      ghq_root: node[:repos],
      config_dir: git_config_dir
    )
  end

  link "#{git_config_dir}/.gitignore_global" do
    to "#{node[:doms_dotfiles]}/config/git/.gitignore_global"
    not_if { File.symlink? "#{git_config_dir}/.gitignore_global" }
  end

  link "#{git_config_dir}/.gitattributes_global" do
    to "#{node[:doms_dotfiles]}/config/git/.gitattributes_global"
    not_if { File.symlink? "#{git_config_dir}/.gitattributes_global" }
  end

  # Platform-specific templates
  %w[darwin darwin_exfat linux windows wsl].each do |platform|
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

  # Install ExFAT cleanup script (runs on post-checkout and post-merge)
  template "#{git_hooks_dir}/cleanup-appledouble" do
    source "templates/git/hooks/cleanup-appledouble.erb"
    mode "755"
    owner node[:user]
    group node[:group]
  end

  # Create symlinks for post-checkout and post-merge hooks
  link "#{git_hooks_dir}/post-checkout" do
    to "#{git_hooks_dir}/cleanup-appledouble"
    not_if { File.exist?("#{git_hooks_dir}/post-checkout") }
  end

  link "#{git_hooks_dir}/post-merge" do
    to "#{git_hooks_dir}/cleanup-appledouble"
    not_if { File.exist?("#{git_hooks_dir}/post-merge") }
  end

  # Configure global hooks path
  execute "git config --global core.hooksPath '#{git_hooks_dir}'" do
    user node[:user]
    not_if "git config --global core.hooksPath | grep -q '#{git_hooks_dir}'"
  end

  # Install standalone cleanup script for ExFAT
  file "#{git_config_dir}/cleanup-git-exfat.sh" do
    content File.read("#{node[:doms_dotfiles]}/cookbooks/git/files/cleanup-git-exfat.sh")
    mode "755"
    owner node[:user]
    group node[:group]
  end

  # Create alias for easy cleanup
  execute "git config --global alias.cleanup-exfat '!bash #{git_config_dir}/cleanup-git-exfat.sh'" do
    user node[:user]
    not_if "git config --global alias.cleanup-exfat"
  end

  execute "git config --global alias.fsck-exfat '!bash #{git_config_dir}/cleanup-git-exfat.sh --repair'" do
    user node[:user]
    not_if "git config --global alias.fsck-exfat"
  end
end

# Windows-specific Git configuration (when not in WSL)
if os == "windows" && !wsl?
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

include_cookbook "git-credential-manager"
