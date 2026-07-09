# https://developer.hashicorp.com/terraform/downloads
include_recipe "dependency.rb"

case node[:platform]
when "arch"
  execute "install terraform" do
    command "sudo pacman -S --noconfirm terraform"
    not_if "which terraform"
  end
when "osx", "darwin"
  execute "tap hashicorp/tap" do
    command "brew tap hashicorp/tap"
    not_if "brew tap | grep -q '^hashicorp/tap$'"
  end

  execute "install terraform" do
    command "brew install hashicorp/tap/terraform"
    not_if "which terraform"
  end
when "fedora"
  execute "install terraform" do
    command <<~EOCMD
      sudo dnf install -y dnf-plugins-core
      sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
      sudo dnf install -y terraform
    EOCMD
    not_if "which terraform"
  end
when "redhat"
  execute "install terraform" do
    command <<~EOCMD
      sudo dnf install -y dnf-plugins-core
      sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      sudo dnf install -y terraform
    EOCMD
    not_if "which terraform"
  end
when "amazon"
  execute "install terraform" do
    command <<~EOCMD
      sudo yum install -y yum-utils
      sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
      sudo yum install -y terraform
    EOCMD
    not_if "which terraform"
  end
when "debian", "ubuntu", "mint"
  execute "install terraform" do
    command <<~EOCMD
      wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
      sudo apt update -y && sudo apt install -y terraform
    EOCMD
    not_if "which terraform"
  end
when "opensuse"
  execute "install terraform" do
    command <<~EOCMD
      sudo zypper install -y zypper
      sudo zypper addrepo https://rpm.releases.hashicorp.com/openSUSE/hashicorp.repo
      sudo zypper install -y terraform
    EOCMD
    not_if "which terraform"
  end
else
  MItamae.logger.warn "terraform install not implemented for platform #{node[:platform]}"
end
