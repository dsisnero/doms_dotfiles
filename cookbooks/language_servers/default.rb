include_cookbook "mise"
include_cookbook "nodejs"

config_home = node[:config_home]
zshrc_config = node[:zshrc_config]
case node[:platform]
when "darwin"
  package "terraform-ls"
  package "bash-language-server"
  package "yaml-language-server"
  package "docker-ls"
  package "ansible-language-server"

  npm_installed = %w[vscode-langservers-extracted typescript typescript-language-server]

  npm_installed.each do |lsp|
    execute("installing #{lsp}") do
      command %(npm i -g #{lsp})
    end
  end

  # Create dprint config directory
  mydir "#{config_home}/dprint"

  mise "marksman"
  mise "dprint"
  # Copy dprint config file
  remote_file "#{config_home}/dprint/config.json" do
    source "files/dprint_config.json"
    owner node[:user]
    mode "644"
  end

  # Add alias for dprint to use the config file
  file zshrc_config do
    action :edit
    content %(alias dprint="dprint --config #{config_home}/dprint/config.json")
    not_if %(grep "alias dprint=" #{zshrc_config})
  end
end
