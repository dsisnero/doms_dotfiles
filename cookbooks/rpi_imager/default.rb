package "snapd"

# Install rpi-imager using system commands since it requires classic confinement
execute "install rpi-imager" do
  command "snap install rpi-imager --classic"
  not_if "snap list | grep -q rpi-imager"
end
