case node[:platform]
when "debian", "mint", "ubuntu"
  package "gpg"
  package "sudo"
  package "wget"
  package "curl"
  package "jq"  # Needed for github_binary plugin
  package "tar"
  package "unzip"
when "darwin"
  package "gpg"
  package "wget"
  package "curl"
  package "jq"  # Needed for github_binary plugin
end
