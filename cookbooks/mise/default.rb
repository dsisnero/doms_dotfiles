include_recipe "dependency.rb"

user_ = node[:user]
home_ = node[:home]
config_home = node[:config_home]
zshrc_config = node[:zshrc_config]

case node[:platform]
when "debian", "mint", "ubuntu"
  # Get config_home from node attributes
  config_home = node[:config_home]

  execute "install mise" do
    command <<~EOCMD
      wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg
      echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
    EOCMD
    not_if "test -f /etc/apt/sources.list.d/mise.list"
  end
  package "mise"

  remote_file "/etc/profile.d/00-mise.sh" do  # ← 00- prefix ensures first load
    source "files/mise-profile.sh"
    mode "644"
    only_if "which mise"
  end

  file "#{home_}/.bashrc" do
    action :edit
    content %[eval "$(mise activate bash)"]
    not_if %(grep 'mise activate' #{home_}/.bashrc)
  end

  file zshrc_config do
    action :edit
    content %[eval "$(mise activate zsh)"]
    not_if %(grep 'mise activate' #{zshrc_config})
  end

  fish_config_dir = "#{config_home}/fish"
  directory fish_config_dir do
    user user_
    group user_
    mode "755"
    not_if { File.exist?(fish_config_dir) }
  end

  fish_config = "#{fish_config_dir}/config.fish"
  file fish_config do
    action :create
    content %(mise activate fish | source)
    not_if { File.exist?(fish_config) }
  end

  file fish_config do
    action :edit
    content %(mise activate fish | source)
    not_if %(grep 'mise activate' #{fish_config})
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
    user node[:user]
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
  content %(export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt")
  not_if %(grep 'MISE_SOPS_AGE_KEY_FILE' #{zshrc_config})
end

file "#{home_}/.bashrc" do
  action :edit
  content %(export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt")
  not_if %(grep 'MISE_SOPS_AGE_KEY_FILE' #{home_}/.bashrc)
end
