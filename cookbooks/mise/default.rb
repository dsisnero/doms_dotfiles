include_recipe "dependency.rb"

user_ = node[:user]
home_ = node[:home]
config_home = node[:config_home]
zshrc_config = node[:zshrc_config]
node[:group]

platform = node[:platform]

MItamae.logger.info "platform #{platform}"

c = <<~HEREDOC
  sudo apt update -y && sudo apt install -y curl
  sudo install -dm 755 /etc/apt/keyrings
  curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc 1> /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt update -y
  sudo apt install -y mise
HEREDOC

MItamae.logger.info "command for install #{c}"
# Raspberry Pi specific packages (if running on ARM architecture)
case node[:platform]
when "ubuntu", "debian", "mint", "pop"
  MItamae.logger.info "installing mise for ubuntu variants"

  execute("install mise") do
    user "root"
    command "sh #{c}"
    not_if "command -v mise"
  end

when "darwin"
  package "mise" do
    not_if "command -v mise"
  end
end

# Keep user config directories but fix ownership
mydir "#{home_}/.config/mise"
mydir "#{home_}/.local/share/mise"
mydir "#{home_}/.cache/mise"
mydir node[:user_bin]

# Update shell integration to use system-installed mise
update_config(zshrc_config, 'eval "$(mise activate zsh)"', owner: user_, group: node[:group])
update_config("#{home_}/.bashrc", 'eval "$(mise activate bash)"', owner: user_, group: node[:group])

define :mise, version: nil, backend: nil, exe: nil, rename: nil do
  tool_name = params[:name]
  version = params[:version] || "latest"
  backend = params[:backend]
  cmd = if backend
    "mise use -g #{backend}:#{tool_name}@#{version}"
  else
    "mise use -g #{tool_name}@#{version}"
  end
  exe = params[:exe] || tool_name

  # MItamae switches to the user through `sudo -H`, which resets PATH to
  # sudo's secure_path. That hides the user's rust/cargo install, so the
  # `cargo:` backend fails with `cargo install ... No such file or
  # directory (os error 2)`. Export the user's PATH explicitly so mise
  # always runs as the user (never root) and can find cargo.
  user_env = %(export PATH="#{home_}/.cargo/bin:#{home_}/.local/share/mise/shims:#{home_}/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH")

  execute "installing #{tool_name}@#{version}" do
    user user_
    command "#{user_env} && #{cmd}"
    not_if "#{user_env} && MISE_AUTO_INSTALL=0 mise which #{exe} >/dev/null 2>&1"
  end
end

mise "sops"
mise "age"
mise "slsa-verifier"
MItamae.logger.info("zshrc_config: #{zshrc_config}")
update_config(zshrc_config, %(export MISE_SOPS_AGE_KEY_FILE="$HOME/.config/mise/age.txt"), owner: user_, group: node[:group])
update_config("#{home_}/.bashrc", %(export MISE_SOPS_AGE_KEY_FILE="$HOME/.config/mise/age.txt"), owner: user_, group: node[:group])

directory "/tmp/mitamae-#{user_}" do
  action :delete
  only_if { file_exists?("/tmp/mitamae-#{user_}") }
end
