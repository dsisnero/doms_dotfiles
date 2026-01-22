# install chrome
case node[:platform]
when "debian", "ubuntu", "mint"
  # Remove duplicate google.list file if it exists
  file "/etc/apt/sources.list.d/google.list" do
    action :delete
    only_if "grep -q 'deb http://dl.google.com/linux/chrome/deb/ stable main' /etc/apt/sources.list.d/google.list"
  end

  apt_repository "google-chrome" do
    url "deb http://dl.google.com/linux/chrome/deb/ stable main"
    gpg_key "https://dl-ssl.google.com/linux/linux_signing_key.pub"
  end

  package "google-chrome-stable"

when "fedora", "redhat", "amazon"
  # not implemented
when "osx", "darwin"
  package "google-chrome"
when "arch"
  include_cookbook "yay"
  yay "google-chrome"
when "opensuse"
  # not implemented
else
  # not implemented
end
