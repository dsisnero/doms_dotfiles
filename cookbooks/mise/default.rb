include_recipe "dependency.rb"

user_ = node[:user]
home_ = node[:home]
config_home = node[:config_home]
zshrc_config = node[:zshrc_config]
node[:group]

# Install mise using github_binary plugin
github_binary "mise" do
  repo "jdx/mise"
  version "latest"
  # Use pattern similar to mise_install.sh
  asset_pattern "mise-v:version-:os-:arch.tar.gz"
  binary_name "mise"
  install_path "#{home_}/.local/bin/mise"
  user user_
  mode "0755"
  strip_components 1  # mise archives have a mise/ directory
end

# Keep user config directories but fix ownership
mydir "#{home_}/.config/mise"

# Update shell integration to use mise
execute "Add mise to #{zshrc_config}" do
  user user_
  command %(
      if ! grep -q 'mise activate zsh' #{zshrc_config}; then
        echo 'eval "$(#{home_}/.local/bin/mise activate zsh)"' >> #{zshrc_config}
      fi
    )
end

define :mise, version: nil, backend: nil, exe: nil, rename: nil do
  tool_name = params[:name]
  version = params[:version] || "latest"
  backend = params[:backend]
  cmd = if backend
    "#{home_}/.local/bin/mise use -g #{backend}:#{tool_name}@#{version}"
  else
    "#{home_}/.local/bin/mise use -g #{tool_name}@#{version}"
  end
  exe = params[:exe] || tool_name
  execute "installing #{tool_name}@#{version}" do
    user user_  # Change from node[:user] to local variable
    command cmd
    not_if "#{home_}/.local/bin/mise exec -- which #{exe}"
  end
end

mise "sops"
mise "age"
mise "slsa-verifier"
execute "Add AGE key to #{zshrc_config}" do
  user user_
  command %(
    if ! grep -q 'MISE_SOPS_AGE_KEY_FILE' #{zshrc_config}; then
      echo 'export MISE_SOPS_AGE_KEY_FILE="#{config_home}/mise/age.txt"' >> #{zshrc_config}
    fi
  )
end

execute "Add mise to #{home_}/.bashrc" do
  user user_
  command %(
      if ! grep -q 'mise activate bash' #{home_}/.bashrc; then
        echo 'eval "$(#{home_}/.local/bin/mise activate bash)"' >> #{home_}/.bashrc
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
