case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  package "keepassxc"
when "windows"
end
