case node[:platform]
when "debian", "mint", "ubuntu", "darwin"
  package "gpg"
  package "sudo"
  package "wget"
  package "curl"
when "darwin"
  package "gpg"
  package "wget"
  package "curl"
end
