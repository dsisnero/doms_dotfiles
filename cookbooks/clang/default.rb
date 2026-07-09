include_recipe "dependency.rb"

case node[:platform]
when "arch"
  execute "install clang" do
    command "sudo pacman -S --noconfirm clang"
    not_if "which clang"
  end
when "osx", "darwin"
  execute "install clang (Xcode Command Line Tools)" do
    command "xcode-select --install"
    not_if "xcode-select -p"
  end
when "fedora", "redhat"
  execute "install clang" do
    command "sudo dnf install -y clang"
    not_if "which clang"
  end
when "amazon"
  execute "install clang" do
    command "sudo yum install -y clang"
    not_if "which clang"
  end
when "debian", "ubuntu", "mint"
  package "clang"
when "opensuse"
  execute "install clang" do
    command "sudo zypper install -y clang"
    not_if "which clang"
  end
else
  MItamae.logger.warn "clang install not implemented for platform #{node[:platform]}"
end
