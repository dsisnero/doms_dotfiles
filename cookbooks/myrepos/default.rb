# download myrepos
node[:user]

myrepos = [
  "nexcom-srf",
  "faa-cost_estimate",
  "autocad",
  "astronvim_config",
  "faa_project",
  "mitamae",
  "xdg",
  "keyring",
  "gmaps",
  "cltk",
  "perdiem",
  "shell2batch.cr"
]
myrepos.each { |name| get_repo "dsisnero/#{name}" }

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
"~/repos/github.com/dsisnero/private-memo/obsidian/work"
# execute "ln -s #{blog_repo_path} #{obsidian_vault_path}/blog" do
#   not_if "test -e #{obsidian_vault_path}/blog"
#   user user
# end
