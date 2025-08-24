# Install rpi-imager using system commands since it requires classic confinement
case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  package "snapd"

  execute "install rpi-imager" do
    command "snap install rpi-imager --classic"
    not_if "snap list | grep -q rpi-imager"
  end
when "osx"
end
