# Dependencies for SSH Server cookbook

case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  # Dependencies for Debian-based systems
  # openssh-server is installed in main cookbook

when "redhat", "fedora", "centos", "amazon"
  # Dependencies for RPM-based systems

when "arch"
  # Dependencies for Arch Linux

when "darwin", "osx"
  # macOS dependencies - SSH server is built-in

when "windows"
  # Windows dependencies - handled by PowerShell in main cookbook

end