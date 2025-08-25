include_recipe "dependency.rb"

case node[:platform]
when "arch"
when "osx", "darwin"
  package "keychain"
when "fedora", "redhat", "amazon"
when "debian", "ubuntu", "mint"
  package "keychain"
when "opensuse"
end
