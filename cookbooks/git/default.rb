# Create a user-specific temporary directory to avoid permission issues
home = node[:home]
config_home = node[:config_home] || "#{home}/.config"
case node[:platform]
when "debian", "ubuntu", "mint"
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
  # Create XDG-compliant hooks directory
  hooks_dir = "#{config_home}/git/hooks"

  # Ensure parent git directory exists
  directory "#{config_home}/git" do
    user node[:user]
    group node[:group]
    mode "755"
  end

  directory hooks_dir do
    user node[:user]
    group node[:group]
    mode "0755"
  end

  # Main .gitconfig with platform-specific includes
  template "#{config_dir}/git/config" do
    source "templates/git/gitconfig.erb"
    owner user
    group group
    mode "644"
    variables(
      platform: node[:platform],
      is_wsl: node[:is_wsl],
      config_dir: node[:config_home]
    )
  end

  # Platform-specific config directory
  mydir "#{config_dir}/git/platforms"

  # Common git configuration
  template "#{config_dir}/git/config.common" do
    source "templates/git/common_config.erb"
    owner user
    group group
    mode "644"
  end

  # Platform-specific templates
  %w[darwin linux windows].each do |platform|
    template "#{config_dir}/git/platforms/#{platform}" do
      source "templates/git/platforms/#{platform}.erb"
      owner user
      group group
      mode "644"
    end
  end

  # WSL template (special case)
  template "#{config_dir}/git/platforms/wsl" do
    source "templates/git/platforms/wsl.erb"
    owner user
    group group
    mode "644"
  end

  # Install pre-commit hook
  template "#{home}/.config/git/hooks/pre-commit" do
    source "templates/git/hooks/pre-commit.erb"
    mode "755"
    owner node[:user]
    group node[:group]
    variables(
      user: node[:user]
    )
  end

  # Install commit-msg hook
  template "#{home}/.config/git/hooks/commit-msg" do
    source "templates/git/hooks/commit-msg.erb"
    mode "755"
    owner node[:user]
    group node[:group]
    variables(
      user: node[:user]
    )
  end

  # Configure global hooks path
  execute "git config --global core.hooksPath '#{hooks_dir}'" do
    user node[:user]
    not_if "git config --global core.hooksPath | grep -q '#{hooks_dir}'"
  end

when "fedora", "redhat", "amazon"
  package "wget"
  package "curl-devel"
  package "expat-devel"
  package "gettext-devel"
  package "openssl-devel"
  package "zlib-devel"
  package "perl-ExtUtils-MakeMaker"
  package "autoconf"

  execute "install git" do
    command <<-EOL
      #!/bin/bash
      VERSION=2.17.1
      WORKDIR=work_git

      cur=$(pwd)
      mkdir -p ${WORKDIR}
      cd ${WORKDIR}

      wget https://www.kernel.org/pub/software/scm/git/git-${VERSION}.tar.gz
      tar fx git-${VERSION}.tar.gz
      cd git-${VERSION}
      make configure
      ./configure --prefix=/usr/local
      make all
      sudo make install

      cd ${cur}
      rm -rf ${WORKDIR}
    EOL
    not_if "test -e /usr/local/bin/git"
  end

when "osx", "darwin"
  package "git"
when "arch"
  package "git"
when "opensuse"
end
