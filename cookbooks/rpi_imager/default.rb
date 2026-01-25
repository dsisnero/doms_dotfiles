# Install rpi-imager by downloading directly from Raspberry Pi website
# This avoids the outdated snap version and gets the latest release
case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  # Determine architecture
  arch = node[:kernel][:machine]
  case arch
  when "x86_64"
    arch = "amd64"
  when "aarch64", "arm64"
    arch = "arm64"
  when "armv7l"
    arch = "armhf"
  end

  # Download URL for the latest .deb package
  # Version can be updated here when new releases are available
  version = "2.0.5"
  deb_file = "imager_#{version}_#{arch}.deb"
  deb_url = "https://downloads.raspberrypi.org/imager/#{deb_file}"

  tmp_dir = "/tmp/rpi-imager-install"

  directory tmp_dir do
    action :create
    owner node[:user]
  end

  downloaded_file = "#{tmp_dir}/#{deb_file}"

  http_request "download rpi-imager" do
    url deb_url
    path downloaded_file
    owner node[:user]
    not_if "which rpi-imager"
  end

  execute "install rpi-imager .deb" do
    command "sudo dpkg -i #{downloaded_file} || sudo apt-get install -f -y"
    cwd tmp_dir
    not_if "which rpi-imager"
  end

  directory tmp_dir do
    action :delete
    only_if { File.exist?(tmp_dir) }
  end

when "osx", "darwin"
  package "raspberry-pi-imager"

when "windows"
  # Windows installation would require downloading the installer
  # Not implemented in this cookbook
  log "Raspberry Pi Imager for Windows not implemented in this cookbook"

when "arch"
  # Arch Linux users can install from AUR: rpi-imager or rpi-imager-bin
  log "Raspberry Pi Imager for Arch Linux not implemented in this cookbook"
end
