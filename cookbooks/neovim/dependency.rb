include_cookbook "ruby"
include_cookbook "python"
include_cookbook "yarn"
include_cookbook "ghq"
include_cookbook "delta"

package "cmake"

# ruby
# gem_package 'neovim'
execute "gem install --user-install neovim" do
  user node[:user]
  command <<-EOCMD
  mise exec
  gem install --user-install neovim
  EOCMD
  not_if "mise exec -- gem list | grep -q 'neovim'"
end

# pip =
%w[
  neovim
  neovim-remote
].each do |pip|
  # cmds =
  %w[
    pip pip
  ].each do |pipcmd|
    execute "#{pipcmd} install --upgrade --user #{pip}" do
      user node[:user]

      command <<-EOCMD
        mise exec
        #{pipcmd} install --upgrade --user #{pip}
      EOCMD
      only_if "mise activate; which #{pipcmd}"
    end
  end
end

# Node.js
execute "install neovim yarn package" do
  command "mise exec -- yarn global add neovim"
  user node[:user]
  not_if "mise exec -- yarn global list | grep -q 'neovim@'"
end

# include_cookbook 'perl'
# execute 'cpanm Neovim::Ext'

# go_get 'github.com/tennashi/vimalter'
execute "install vimalter" do
  command <<-EOCMD
    mkdir work_vimalter
    cd work_vimalter
    wget https://github.com/tennashi/vimalter/releases/download/0.1.0/vimalter_0.1.0_Linux_64-bit.tar.gz -O vimalter.tar.gz
    tar xfz  vimalter.tar.gz
    mv vimalter ~/.local/bin
    cd ..
    rm -rf work_vimalter
  EOCMD
  user node[:user]
  not_if "test -f ~/.local/bin/vimalter"
end

# if arch package 'fd'
package "fd-find"
execute "ln -s $(which fdfind) ~/.local/bin/fd" do
  user node[:user]
  not_if "test -f ~/.local/bin/fd"
end
