include_cookbook "mise"
include_cookbook "nodejs"

node[:config_home]
node[:zshrc_config]

case node[:platform]
when "darwin"
  # On macOS, use Homebrew packages where available
  package "terraform-ls"
  package "bash-language-server"
  package "yaml-language-server"
  package "docker-ls"
  package "ansible-language-server"

  # npm packages installed globally via npm
  npm_installed = %w[vscode-langservers-extracted typescript typescript-language-server tombi prettier]
  npm_installed.each do |lsp|
    execute("installing #{lsp}") do
      command %(npm i -g #{lsp})
    end
  end

  # Use mise for tools that are better managed by mise
  mise "marksman"
  mise "dprint"
  mise "taplo"
else
  # For Linux platforms (debian, ubuntu, mint, pop, fedora, etc.) use mise for everything
  # Language servers available via mise plugins
  mise "terraform-ls"
  mise "bash-language-server" do
    backend "npm"
  end
  mise "yaml-language-server" do
    backend "npm"
  end
  mise "dockerfile-language-server-nodejs" do
    backend "npm"
  end
  mise "ansible-language-server" do
    backend "npm"
  end

  # npm packages via mise with npm backend
  mise "vscode-langservers-extracted" do
    backend "npm"
  end
  mise "typescript" do
    backend "npm"
  end
  mise "typescript-language-server" do
    backend "npm"
  end
  mise "tombi" do
    backend "npm"
  end
  mise "prettier" do
    backend "npm"
  end

  # Additional tools via mise
  mise "marksman"
  mise "dprint"
  mise "taplo"
end
