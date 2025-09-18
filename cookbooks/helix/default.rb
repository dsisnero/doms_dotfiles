include_cookbook "ghq"
include_cookbook "rust"
ghq_root = node[:ghq_root]
config_home = node[:config_home]
node[:user]
home = node[:home]
doms_dotfiles = node[:doms_dotfiles]
config_dir = node[:config_home]

# include_cookbook "mise"

# mise "helix" do
#   exe "hx"
# end

dest = "#{config_dir}/helix/snippets"
src = "#{doms_dotfiles}/config/helix/snippets"

link dest do
  to src
  user node[:user]
  not_if "test -d #{dest}"
end

# # Special handling for snippets directory
# execute "symlink helix snippets" do
#   command "ln -sfT #{doms_dotfiles}/config/helix/snippets #{config_dir}/helix/snippets"
#   user user
#   only_if "test -d #{doms_dotfiles}/config/helix/snippets"
#   not_if "test -L #{config_dir}/helix/snippets"
# end

get_repo("helix-editor/helix")

dir = File.join(ghq_root, "github.com/helix-editor/helix")
cargo "helix-locked" do
  path "#{dir}/helix-term"
  cwd dir
end

src = File.expand_path(File.join(dir, "runtime"))
dest = "#{config_home}/helix/runtime"
link dest do
  to src
  user node[:user]
  not_if "test -d #{dest}"
end

# share_dir = "#{home}/.local/share"

# mydir share_dir
# mydir "#{share_dir}/icons"
# mydir "#{share_dir}/applications"
# # copy the desktop icons
# execute "copy helix desktop icons" do
#   user user
#   command <<~EOS
#       cp #{dir}/contrib/Helix.desktop #{share_dir}/applications
#     cp #{dir}/contrib/helix.png  #{share_dir}/icons
#   EOS
# end

# change_links_cmd = <<~EOS
#   sed -i -e "s|Exec=hx %F|Exec=$(readlink -f ~/.cargo/bin/hx) %F|g" \
#     -e "s|Icon=helix|Icon=$(readlink -f #{share_dir}/icons/helix.png)|g" #{share_dir}/applications/Helix.desktop
# EOS

# execute "change links in helix .desktop file to absolute paths" do
#   user user
#   command change_links_cmd
# end

# # add HELIX_RUNTIME to .bashrc
# execute "add HELIX_RUNTIME to .bashrc" do
#   command "echo 'export HELIX_RUNTIME=#{dir}/runtime' >> #{home}/.bashrc"
#   not_if "grep 'export HELIX_RUNTIME' #{home}/.bashrc"
# end

# cargo = "#{home}/.cargo/bin/cargo"
#   # execute "#{sudo(node[:user])}ghq get helix-editor/helix"
#   execute 'install helix' do
# dir = File.join( ghq_root, "github.com/helix-editor/helix")
#     command <<-EOL
#       set -eu
#       #{sudo(node[:user])}cd #{dir}
#       #{cargo} install --path #{dir}/helix-term --locked
#     EOL
#     user user

#     not_if 'test -e /usr/local/bin/helix'
#   end

file "#{home}/.bashrc" do
  action :edit
  not_if "grep 'export EDITOR=hx' #{home}/.bashrc"
  content %(export EDITOR=hx)
end

zshrc_config = node[:zshrc_config]
file zshrc_config do
  action :edit
  not_if "grep 'export EDITOR=hx' #{zshrc_config}"
  content %(export EDITOR=hx)
end

mise "marksman"
mise "dprint"
