case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  flatpak "org.keepassxc.KeePassXC"
when "windows"
end
