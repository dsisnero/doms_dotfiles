# download myrepos
user = node[:user]

myrepos = [
  "dsisnero/doms_dotfiles",
  "dsisnero/terminal-tools",
  "dsisnero/myvim_dict",
  "dsisnero/dash_snippet",
  "dsisnero/mysnip",
  "dsisnero/vim-template",
  "dsisnero/powerline-ext-tmux",
  "dsisnero/blog.dsisnero",
  "dsisnero/dsisnero.github.io",
  "dsisnero/private-memo.git"
]
myrepos.each { |name| get_repo name }

directory "~/.local/share/fonts" do
  owner node[:user]
  group node[:group]
end

# install_font "#{node[:home]}/repos/gitlab.com/dsisnero/RictyDiminished-for-Powerline/Ricty_Diminished_Discord_Regular_for_Powerline.ttf"
# install_font "#{node[:home]}/repos/gitlab.com/dsisnero/RictyDiminished-for-Powerline/Ricty_Diminished_Discord_Oblique_for_Powerline.ttf"
# install_font "#{node[:home]}/repos/gitlab.com/dsisnero/RictyDiminished-for-Powerline/Ricty_Diminished_Discord_Bold_for_Powerline.ttf"
# install_font "#{node[:home]}/repos/gitlab.com/dsisnero/RictyDiminished-for-Powerline/Ricty_Diminished_Discord_Bold_Oblique_for_Powerline.ttf"
# install_font "#{node[:home]}/repos/gitlab.com/dsisnero/RictyDiminished-for-Powerline/Ricty_Diminished_Regular_for_Powerline.ttf"
# install_font "#{node[:home]}/repos/gitlab.com/dsisnero/RictyDiminished-for-Powerline/Ricty_Diminished_Bold_for_Powerline.ttf"
# install_font "#{node[:home]}/repos/gitlab.com/dsisnero/RictyDiminished-for-Powerline/Ricty_Diminished_Bold_Oblique_for_Powerline.ttf"
# install_font "#{node[:home]}/repos/gitlab.com/dsisnero/RictyDiminished-for-Powerline/Ricty_Diminished_Oblique_for_Powerline.ttf"

blog_repo_path = "~/repos/github.com/dsisnero/blog.dsisnero"
obsidian_vault_path = "~/repos/github.com/dsisnero/private-memo/obsidian/work"
execute "ln -s #{blog_repo_path} #{obsidian_vault_path}/blog" do
  not_if "test -e #{obsidian_vault_path}/blog"
  user user
end
