case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  # Try to use flatpak if plugin is available, otherwise use apt
  begin
    flatpak "org.keepassxc.KeePassXC"
  rescue NoMethodError
    package "keepassxc"
  end
when "windows"
when "darwin"
  package "KeePassXC"
end
