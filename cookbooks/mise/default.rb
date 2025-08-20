include_recipe "dependency.rb"

user_ = node[:user]
home_ = node[:home]
config_home = node[:config_home]
zshrc_config = node[:zshrc_config]
group_ = node[:group]

case node[:platform]
when "debian", "mint", "ubuntu"

  # Create keyring directory
  directory "/etc/apt/keyrings" do
    mode "755"
    owner "root"
    group "root"
  end

  # Add repository (using standard apt_repository pattern)
  apt_repository "mise" do
    # Full repository line including components
    url "https://mise.jdx.dev/deb stable main"
    # Use arch= in URL instead of separate attribute
    # The following block is a more robust way to ensure the arch is added if not present
    # and handles the case where the URL might change slightly.
    # However, the plugin does not support a content block directly on apt_repository.
    # We will assume the plugin handles the 'deb [arch=amd64] ...' format directly in the url.
    # For now, we will set the url directly as per the user's simplified request.
    # A more complex solution would involve modifying the plugin or using a file resource.
    # url "https://mise.jdx.dev/deb stable main" do |content|
    #   content.gsub!(/^deb /, 'deb [arch=amd64] ')
    # end
    # For the direct application as requested:
    gpg_key "https://mise.jdx.dev/gpg-key.pub"
    notifies :update, "apt_update", :immediately
  end

  # Install system package
  package "mise" do
    action :install
    version nil  # Install latest available
  end

when "fedora", "redhat", "amazon"

when "osx", "darwin"
  package "mise"
end

# Remove previous user install leftovers
file "#{home_}/.local/bin/mise" do
  action :delete
  only_if "test -f #{home_}/.local/bin/mise"
end

# Keep user config directories but fix ownership
directory "#{home_}/.config/mise" do
  user user_
  group group_
  mode "755"
end

# Update shell integration to use system-installed mise
execute "Add mise to #{zshrc_config}" do
  user user_
  command %(
      if ! grep -q 'mise activate zsh' #{zshrc_config}; then
        echo 'eval "$(mise activate zsh)"' >> #{zshrc_config}
      fi
    )
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
