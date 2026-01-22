# Install rpi-imager using system commands since it requires classic confinement
# Raspberry Pi Imager is available for macOS via Homebrew and Linux via snap
case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  # Ensure snapd is installed and enabled
  package "snapd"

  execute "enable snapd socket" do
    command "systemctl enable --now snapd.socket"
    not_if "systemctl is-enabled snapd.socket 2>/dev/null | grep -q enabled"
  end

  execute "create snap symlinks" do
    command "ln -sf /var/lib/snapd/snap /snap"
    not_if "test -L /snap"
  end

  execute "install rpi-imager" do
    command "snap install rpi-imager --classic"
    not_if "snap list | grep -q rpi-imager"
  end

when "osx", "darwin"
  package "raspberry-pi-imager"

when "windows"
  # Windows installation would require downloading the installer
  # Not implemented in this cookbook
  log "Raspberry Pi Imager for Windows not implemented in this cookbook"
end
