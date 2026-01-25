# Dependencies for podman cookbook
case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  # Basic dependencies for container management
  package "curl"
  package "gnupg"
  package "software-properties-common"

when "osx", "darwin"
  # No special dependencies for macOS via Homebrew

when "arch"
  # Arch Linux dependencies would go here
  log "Podman dependencies for Arch Linux not implemented"

when "windows"
  # Windows dependencies would go here
  log "Podman dependencies for Windows not implemented"
end
