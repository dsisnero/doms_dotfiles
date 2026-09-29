# Install HandBrake
case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  package "handbrake"
when "arch"
  package "handbrake"
when "osx", "darwin"
  package "handbrake"
when "fedora", "redhat", "amazon", "opensuse"
  log "HandBrake for Fedora/RHEL requires RPM Fusion (HandBrake-gui/HandBrake); not implemented in this cookbook"
when "windows"
  log "HandBrake for Windows is not implemented in this cookbook"
else
  log "HandBrake installation not implemented for this platform"
end