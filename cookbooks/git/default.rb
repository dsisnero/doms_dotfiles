# Create a user-specific temporary directory to avoid permission issues

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
  hooks_dir = "#{node[:config_home]}/git/hooks"
  directory hooks_dir do
    user node[:user]
    group node[:group]
    mode "0755"
  end

  # Deploy all hook files
  Dir.glob("files/*").each do |hook|
    basename = File.basename(hook)
    remote_file "#{hooks_dir}/#{basename}" do
      source hook
      mode "0755"
      user node[:user]
      group node[:group]
      # Use user-specific temporary directory
    end
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
