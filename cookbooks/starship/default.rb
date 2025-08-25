# インストールスクリプトのダウンロード
include_cookbook "mise"

mise "starship"

case node[:platform]

when "osx", "ubuntu", "mint", "darwin"
  home = node[:home]

  file "#{home}/.bashrc" do
    action :edit
    content %[eval "$(starship init bash)"]
    not_if %(grep 'starship init' #{home}/.bashrc)
  end

  zshrc_config = node[:zshrc_config]
  file zshrc_config do
    action :edit
    content %[eval "$(starship init zsh)"]
    not_if %(grep 'starship init' #{zshrc_config})
  end

else
  # do nothing
end

dotfile "starship"
