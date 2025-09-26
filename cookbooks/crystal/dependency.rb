# package "llvm"
# package "clang"
# package "lldb"
# package "llvm-dev"
# package "libclang-dev"
# package "libz-dev"
# package "libstdc++-dev"
case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  %w[
    automake
    build-essential
    git
    libbsd-dev
    libevent-dev
    libgmp-dev
    libgmpxx4ldbl
    libpcre2-dev
    libssl-dev
    libtool
    libxml2-dev
    libyaml-dev
    lld
    libz-dev
    clang
    libclang-dev
    lldb
  ].each do |pkg|
    package pkg
  end
  include_cookbook "llvm"
when "osx", "darwin"
  include_cookbook "llvm"
when "redhat"
end
