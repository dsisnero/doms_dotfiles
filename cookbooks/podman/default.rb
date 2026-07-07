# Install podman container runtime
include_recipe "dependency.rb"
include_cookbook "mise"

case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  package "podman"
  package "podman-compose"
  mise "podman-tui" do
    backend "cargo"
  end

when "osx", "darwin"
  package "podman"
  package "podman-compose"
  package "podman-tui"

  # Note: On macOS, podman requires a Linux VM
  # Users can start it manually with `podman machine init` and `podman machine start`
  # Or install podman-desktop cask for GUI management

when "arch"
  package "podman"
  package "podman-compose"
  package "podman-tui"

when "windows"
  # Windows installation would require WSL2 or native Windows version
  log "Podman for Windows not implemented in this cookbook"
end
