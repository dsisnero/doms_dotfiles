# Install LibreOffice
case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  package "libreoffice"
when "fedora", "redhat", "amazon", "opensuse"
  package "libreoffice"
when "arch"
  package "libreoffice-fresh"
when "osx", "darwin"
  package "libreoffice"
when "windows"
  log "LibreOffice for Windows is not implemented in this cookbook"
else
  log "LibreOffice installation not implemented for this platform"
end