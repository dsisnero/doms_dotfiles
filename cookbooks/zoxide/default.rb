include_cookbook "mise"

mise "zoxide"

home = node[:home]
file "#{home}/.bashrc" do
  action :edit
  not_if "grep 'zoxide init bash' #{home}/.bashrc"
  content %(eval "$(zoxide init bash)")
end

zshrc_config = node[:zshrc_config]
file zshrc_config do
  action :edit
  content %(eval "$(zoxide init zsh)")
  not_if "grep 'zoxide init zsh' #{zshrc_config}"
end
