include_recipe "dependency.rb"

user_ = node[:user]
home_ = node[:home]
config_home = node[:config_home]
zshrc_config = node[:zshrc_config]

case node[:platform]
when "debian", "mint", "ubuntu"
  # Create user-owned directories first
  directory "#{home_}/.local/share/mise" do
    user user_
    mode "755"
  end

  directory "#{home_}/.config/mise" do
    user user_
    mode "755"
  end

  # Install mise using official method as regular user
  execute "install mise" do
    user user_
    command "curl -fsSL https://mise.jdx.dev/install.sh | sh"
    not_if "which mise"
  end

  # Ensure mise is in user's PATH
  file "#{home_}/.bashrc" do
    action :edit
    content %(export PATH="#{home_}/.local/bin:$PATH")
    not_if %(grep '$HOME/.local/bin' #{home_}/.bashrc)
  end

  remote_file "/etc/profile.d/00-mise.sh" do  # ← 00- prefix ensures first load
    source "files/mise-profile.sh"
    owner user_  # Add this line
    group user_  # Add this line
    mode "644"
    only_if "which mise"
  end

  file "#{home_}/.bashrc" do
    action :edit
    content %[eval "$(mise activate bash)"]
    not_if %(grep 'mise activate' #{home_}/.bashrc)
  end

  file zshrc_config do
    user user_  # Add this line
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
    user user_  # Add this line
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
  content %(export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt")
  not_if %(grep 'MISE_SOPS_AGE_KEY_FILE' #{zshrc_config})
end

file "#{home_}/.bashrc" do
  action :edit
  content %(export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt")
  not_if %(grep 'MISE_SOPS_AGE_KEY_FILE' #{home_}/.bashrc)
end
