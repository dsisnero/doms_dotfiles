include_cookbook "mise"
include_cookbook "nodejs"

config_home = node[:config_home]

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

dotfile "rumdl"

mise "rumdl" do
  backend "cargo"
end
