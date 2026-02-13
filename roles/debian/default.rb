# Debian platform role - includes base system packages for Debian-based systems
# Used by Debian, Raspberry Pi OS, and other Debian derivatives

# Remove nano if present (prefer vim/neovim)
execute "sudo apt purge -y nano" do
  only_if "which nano"
end

include_cookbook "rpi_imager"

# Update package lists and upgrade existing packages
execute "sudo apt update"
execute "sudo apt upgrade -y"

include_role("base")

# Raspberry Pi specific packages (if running on ARM architecture)
if node[:kernel] && node[:kernel][:machine] =~ /arm|aarch64/
  MItamae.logger.info "Detected ARM architecture (#{node[:kernel][:machine]}), installing Raspberry Pi specific packages"

  # Raspberry Pi utilities
  package "raspi-config"
  package "pi-bluetooth"
  package "rpi-eeprom"

  # Enable SPI and I2C if needed
  execute "raspi-config nonint do_spi 0" do
    user "root"
    only_if "which raspi-config"
  end
  execute "raspi-config nonint do_i2c 0" do
    user "root"
    only_if "which raspi-config"
  end

  # Ensure video group for user access to video devices
  execute "usermod -a -G video #{node[:user]}" do
    user "root"
    not_if "groups #{node[:user]} | grep -q video"
  end

  include_role "minimal"
end

# Development tools and libraries
package "build-essential"
package "apt-file"
package "patch"
package "zlib1g-dev"
package "liblzma-dev"
package "libxml2-dev"
package "cmake"
package "libboost-all-dev"
package "libicu-dev"

# X11 utilities (optional, useful for graphical environments)
package "x11-apps"
package "x11-utils"
package "x11-xserver-utils"
package "fonts-ipafont"

# Network and utilities
package "aria2"

# Media packages (basic)
package "vlc"
package "ffmpeg"

# DVD playback support
package "libdvd-pkg"
execute "sudo dpkg-reconfigure libdvd-pkg" do
  only_if "dpkg -l | grep -q libdvd-pkg"
end
