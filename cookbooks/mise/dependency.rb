case node[:platform]
when "debian", "mint", "ubuntu"
  package "gpg"
  package "sudo"
  package "wget"
  package "curl"
end
