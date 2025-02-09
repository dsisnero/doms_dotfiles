# package "llvm"
# package "clang"
# package "lldb"
# package "llvm-dev"
# package "libclang-dev"
# package "libz-dev"
# package "libstdc++-dev"
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
  llvm
  llvm-dev
  libz-dev
  clang
  libclang-dev
  lldb
].each do |pkg|
  package pkg
end
