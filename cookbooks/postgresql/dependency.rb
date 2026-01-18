case node[:platform]
when "debian", "ubuntu", "mint"
  %w[
    build-essential
    libssl-dev
    libreadline-dev
    zlib1g-dev
  ].each { |pkg| package pkg }

when "fedora", "redhat", "amazon"
  %w[
    gcc
    gcc-c++
    make
    openssl-devel
    readline-devel
    zlib-devel
  ].each { |pkg| package pkg }

when "arch"
  %w[
    base-devel
    openssl
    readline
    zlib
  ].each { |pkg| package pkg }

when "osx", "darwin"
  # Dependencies are handled by Homebrew

when "opensuse"
  %w[
    gcc
    gcc-c++
    make
    libopenssl-devel
    readline-devel
    zlib-devel
  ].each { |pkg| package pkg }
end