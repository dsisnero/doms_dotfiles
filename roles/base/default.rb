node.reverse_merge!({
  mysql: {
    root_password: "D12uM3m4y+"
  }
})

home = node[:home]

include_cookbook "sudo_nopassword"
include_cookbook "dotfiles"
include_cookbook "git"
include_cookbook "git-secrets"
include_cookbook "go"
include_cookbook "ghq"

include_cookbook "rust"

cargo "cargo-edit"
cargo "cargo-script"
cargo "cargo-update"
cargo "cargo-watch"
cargo "fd-find"

cargo "fnm"

file "#{home}/.bashrc" do
  action :edit
  block do |content|
    content << %[eval "$(fnm env --use-on-cd --shell bash)"]
  end
  not_if %(grep 'fnm env' #{home}/.bashrc)
end

cargo "exa"
cargo "git-delta"
cargo "ripgrep"
cargo "starship"

file "#{home}/.bashrc" do
  action :edit
  block do |content|
    content << %[eval "$(starship init bash)"]
  end
  not_if %(grep 'starship init' #{home}/.bashrc)
end

cargo "bottom"
cargo "broot"
cargo "du-dust"
cargo "zoxide"

include_cookbook "perl"
# include_cookbook 'perl' if not %w(ubuntu debian).include?(node[:platform])
include_cookbook "ruby" # git hookスクリプトで必要なので先にインストールする'
include_cookbook "python"
include_cookbook "nodejs"
include_cookbook "yarn"
include_cookbook "alacritty"

include_cookbook "helix"

cargo "simple-completion-language-server" do
  git "https://github.com/estin/simple-completion-language-server.git"
end

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
