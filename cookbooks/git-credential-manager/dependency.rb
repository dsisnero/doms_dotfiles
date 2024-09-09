case node[:platform]
when "arch"
when "osx", "darwin"
when "fedora", "redhat", "amazon"
when "debian", "ubuntu", "mint"
  package "libsecret-1-0"
  package "libsecret-1-dev"
when "opensuse"
end
