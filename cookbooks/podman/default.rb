# Install podman container runtime
include_recipe "dependency.rb"

case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  package "podman"
  package "podman-compose"
  package "podman-tui"

when "osx", "darwin"
  package "podman"
  package "podman-compose"
  package "podman-tui"

  # Note: On macOS, podman requires a Linux VM
  # Users can start it manually with `podman machine init` and `podman machine start`
  # Or install podman-desktop cask for GUI management

when "arch"
  # Arch Linux users can install from community repo
  log "Podman for Arch Linux not implemented in this cookbook"

when "windows"
  # Windows installation would require WSL2 or native Windows version
  log "Podman for Windows not implemented in this cookbook"
end
