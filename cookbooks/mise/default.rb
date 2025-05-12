include_recipe "dependency.rb"

user_ = node[:user]
home_ = node[:home]
config_home = node[:config_home]
zshrc_config = node[:zshrc_config]

case node[:platform]
when "debian", "mint", "ubuntu"
  # Install required system packages
  %w[gpg wget curl].each do |pkg|
    package pkg
  end

  # Create keyring directory
  directory "/etc/apt/keyrings" do
    mode "755"
    owner "root"
    group "root"
  end

  # Add GPG key (same pattern as Docker/GitHub CLI cookbooks)
  execute "add mise gpg key" do
    command <<-SH
      wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor > /tmp/mise-archive-keyring.gpg && \
      mv /tmp/mise-archive-keyring.gpg /etc/apt/keyrings/
    SH
    not_if "test -f /etc/apt/keyrings/mise-archive-keyring.gpg"
  end

  # Add repository (using standard apt_repository pattern)
  apt_repository "mise" do
    uri "https://mise.jdx.dev/deb"
    distribution "stable"
    components ["main"]
    arch "amd64"
    key "/etc/apt/keyrings/mise-archive-keyring.gpg"
    notifies :run, "execute[apt-update]", :immediately
  end

  # Install system package
  package "mise" do
    action :install
    version nil  # Install latest available
  end

  # Remove previous user install leftovers
  file "#{home_}/.local/bin/mise" do
    action :delete
    only_if "test -f #{home_}/.local/bin/mise"
  end

  # Keep user config directories but fix ownership
  directory "#{home_}/.config/mise" do
    user user_
    group user_
    mode "755"
  end

  # Update shell integration to use system-installed mise
  file zshrc_config do
    user user_
    group user_
    mode "644"
    action :edit
    content %(eval "$(mise activate zsh)")
    not_if %(grep 'mise activate zsh' #{zshrc_config})
  end

when "fedora", "redhat", "amazon"

when "osx", "darwin"
end

define :mise, version: nil, cargo: nil, exe: nil, rename: nil do
  tool_name = params[:name]
  version = params[:version] || "latest"
  cmd = "mise use -g #{tool_name}@#{version}"
  exe = params[:exe] || tool_name
  execute "installing #{tool_name}@#{version}" do
    user user_  # Change from node[:user] to local variable
    command cmd
    not_if "mise exec -- which #{exe}"
  end
end

mise "sops"
mise "age"
mise "slsa-verifier"
puts node
MItamae.logger.info("zshrc_config: #{zshrc_config}")
file zshrc_config do
  action :edit
  user user_
  group user_
  content %(export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt")
  not_if %(grep 'MISE_SOPS_AGE_KEY_FILE' #{zshrc_config})
end

file "#{home_}/.bashrc" do
  action :edit
  content %(export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt")
  not_if %(grep 'MISE_SOPS_AGE_KEY_FILE' #{home_}/.bashrc)
end

directory "/tmp/mitamae-#{user_}" do
  action :delete
  only_if { File.exist?("/tmp/mitamae-#{user_}") }
end
