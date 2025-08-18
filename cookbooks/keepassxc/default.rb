case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  flatpak "org.keepassxc.KeePassXC"
when "windows"
when "darwin"
  package "KeePassXC"
end
