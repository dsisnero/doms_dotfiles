# Base role - essential packages for every system
# Cross-platform essentials: curl, git, core utilities

case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  # Debian-based systems
  package "curl"
  package "wget"
  package "sudo"
  package "openssh-server"
  package "htop"
  package "vim"
  package "ca-certificates"
  package "less"
  package "rsync"
  package "net-tools"
  package "dnsutils"
  package "iputils-ping"
  package "traceroute"
  package "unzip"
  package "zip"
  package "tar"
  package "gzip"
  package "bzip2"
  package "xz-utils"
  package "file"
  package "locales"
  execute "locale-gen en_US.UTF-8"

when "redhat", "fedora", "amazon"
  # RPM-based systems
  package "curl"
  package "wget"
  package "sudo"
  package "openssh-server"
  package "htop"
  package "vim-enhanced"
  package "ca-certificates"
  package "less"
  package "rsync"
  package "net-tools"
  package "bind-utils"
  package "iputils"
  package "traceroute"
  package "unzip"
  package "zip"
  package "tar"
  package "gzip"
  package "bzip2"
  package "xz"
  package "file"
  package "langpacks-en"
  execute "localectl set-locale LANG=en_US.UTF-8"

when "arch"
  # Arch Linux
  package "curl"
  package "wget"
  package "sudo"
  package "openssh"
  package "htop"
  package "vim"
  package "ca-certificates"
  package "less"
  package "rsync"
  package "net-tools"
  package "bind-tools"
  package "iputils"
  package "traceroute"
  package "unzip"
  package "zip"
  package "tar"
  package "gzip"
  package "bzip2"
  package "xz"
  package "file"
  package "glibc"
  execute "locale-gen en_US.UTF-8"

when "darwin", "osx"
  # macOS via Homebrew
  package "curl"
  package "wget"
  # sudo is built-in
  # openssh-server is built-in (enable via system preferences)
  package "htop"
  package "vim"
  package "ca-certificates"
  package "less"
  package "rsync"
  # net-tools not available, use iproute2mac?
  package "bind"  # provides dig, nslookup
  # iputils not available
  package "traceroute"
  package "unzip"
  package "zip"
  package "tar"
  package "gzip"
  package "bzip2"
  package "xz"
  package "file"
  # locales handled by system

when "windows"
  # Windows - minimal support
  MItamae.logger.info "Windows base packages not yet implemented"
  # Could use Chocolatey: choco install curl wget git sudo openssh htop vim etc.
  # For now, skip
end

# Platform-agnostic essentials (if any)
# These will use the appropriate package manager for each platform
# No platform-agnostic packages here since package names differ

# Git configuration (installs git and sets up config)
include_cookbook "git"

# Ensure basic directories exist
directory node[:user_bin] do
  owner node[:user]
  group node[:group]
  mode "755"
end

# Ensure ~/.local/bin is in PATH
file "#{node[:home]}/.bashrc" do
  action :edit
  block do |content|
    unless /export PATH.*\.local\/bin/.match?(content)
      content << "\nexport PATH=\"$HOME/.local/bin:$PATH\"\n"
    end
  end
  only_if { node[:platform] != "windows" }
end
