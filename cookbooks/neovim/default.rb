include_recipe "dependency.rb"
include_cookbook "mise"

node.reverse_merge!(
  neovim: {
    version: "stable"
  }
)

execute "install neovim via mise" do
  user node[:user]
  command "mise use -g neovim@#{node[:neovim][:version]}"
  not_if "which nvim"
end

case node[:platform]
when "debian", "ubuntu", "mint"
  package "ninja-build"
  package "gettext"
  package "libtool"
  package "libtool-bin"
  package "autoconf"
  package "automake"
  package "cmake"
  package "g++"
  package "pkg-config"
  package "unzip"
  package "curl"
  package "doxygen"

when "fedora", "redhat", "amazon"
  package "libtool"
  package "autoconf"
  package "automake"
  package "cmake"
  package "gcc"
  package "gcc-c++"
  package "make"
  package "pkgconfig"
  package "unzip"

when "osx", "darwin"
when "arch"
when "opensuse"
end
