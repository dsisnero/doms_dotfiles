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
  end

when "darwin"
  package "mise"
end

# Keep user config directories but fix ownership
mydir "#{home_}/.config/mise"
mydir node[:user_bin]

# Update shell integration to use system-installed mise
execute "Add mise to #{zshrc_config}" do
  user user_
  command %(
      if ! grep -q 'mise activate zsh' #{zshrc_config}; then
        echo 'eval "$(mise activate zsh)"' >> #{zshrc_config}
      fi
    )
end
home = node[:home]
bash_config = File.join(home, ".bashrc")
execute "Add mise to #{bash_config}" do
  user user_
  command %(
      if ! grep -q 'mise activate zsh' #{bash_config}; then
        echo 'eval "$(mise activate zsh)"' >> #{bash_config}
      fi
    )
end

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
  execute "installing #{tool_name}@#{version}" do
    user user_  # Change from node[:user] to local variable
    command cmd
    not_if "mise exec -- which #{exe}"
  end
end

mise "sops"
mise "age"
mise "slsa-verifier"
MItamae.logger.info("zshrc_config: #{zshrc_config}")
execute "Add AGE key to #{zshrc_config}" do
  user user_
  command %(
    if ! grep -q 'MISE_SOPS_AGE_KEY_FILE' #{zshrc_config}; then
      echo 'export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt"' >> #{zshrc_config}
    fi
  )
end

execute "Add AGE key to #{home_}/.bashrc" do
  user user_
  command %(
    if ! grep -q 'MISE_SOPS_AGE_KEY_FILE' #{home_}/.bashrc; then
      echo 'export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt"' >> #{home_}/.bashrc
    fi
  )
end

directory "/tmp/mitamae-#{user_}" do
  action :delete
  only_if { File.exist?("/tmp/mitamae-#{user_}") }
end
