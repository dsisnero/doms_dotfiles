node.reverse_merge!({
  mysql: {
    root_password: "D12uM3m4y+"
  }
})
package "pass" do
  action :remove
end

include_cookbook "keepassxc"
home = node[:home]
include_cookbook "sudo_nopassword"
include_cookbook "mise"
include_cookbook "keychain"
mise "node"
mise "lua-language-server"
mise "stylua"
mise "fd"
mise "rg"
mise "cargo-binstall"
mise "bat"
mise "git-cliff"
mise "grex"
mise "hyperfine"
mise "ripgrep-all"
mise "bottom"
mise "dust"
mise "tree-sitter"
mise "watchexec"
mise "zoxide"
mise "rclone"
mise "atuin"
mise "mermaid" do
  backend "npm"
end
mise "pandoc"

include_cookbook "dprint"
include_cookbook "starship"
include_cookbook "ghq"
include_cookbook "dotfiles"
include_cookbook "git"
include_cookbook "git-secrets"
include_cookbook "rust"
include_cookbook "helix"
include_cookbook "golang"
include_cookbook "zig"
include_cookbook "vscode"

include_cookbook "treesitter"
package "pdftk-java"

cargo "broot"
cargo "cargo-edit"
cargo "cargo-update"
cargo "cargo-watch"
cargo "exa"
cargo "ouch"

# include_cookbook "ollama"

file "#{home}/.bashrc" do
  action :edit
  content %[eval "$(fnm env --use-on-cd --shell bash)"]
  not_if %(grep 'fnm env' #{home}/.bashrc)
end
cargo "git-delta"
cargo "oxipng"
cargo "sqlx-cli"

cargo "trippy"
cargo "simple-completion-language-server" do
  git "https://github.com/estin/simple-completion-language-server.git"
  features "citation"
end

# include_cookbook "perl"
# include_cookbook 'perl' if not %w(ubuntu debian).include?(node[:platform])
include_cookbook "ruby" # git hookスクリプトで必要なので先にインストールする'
include_cookbook "python"
include_cookbook "yarn"
# include_cookbook "alacritty"
include_cookbook "crystal"

include_cookbook "wezterm"
include_cookbook "lazygit"
include_cookbook "tmux"
include_cookbook "neovim"
include_cookbook "zsh"
include_cookbook "mysql"
include_cookbook "zeroconf"
include_cookbook "chrome"
include_cookbook "direnv"

include_cookbook "myrepos"
include_cookbook "fonts"
include_cookbook "favorite_repos"
include_cookbook "calibre"
include_cookbook "podman"
