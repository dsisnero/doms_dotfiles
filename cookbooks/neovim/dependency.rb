include_cookbook "ruby"
include_cookbook "python"
include_cookbook "yarn"
include_cookbook "ghq"
include_cookbook "delta"

package "cmake"

# Install Ruby neovim gem via mise
execute "install neovim gem" do
  user node[:user]
  command "mise exec -- gem install --user-install neovim"
  not_if "mise exec -- gem list | grep -q 'neovim'"
end

# Install Python neovim packages via mise
%w[neovim neovim-remote].each do |pkg|
  execute "install #{pkg} via pip" do
    user node[:user]
    command "mise exec -- pip install --upgrade --user #{pkg}"
    not_if "mise exec -- pip list --user | grep -q '^#{pkg} '"
  end
end

# Install vimalter (neovim version manager)
execute "install vimalter" do
  command <<-EOCMD
    mkdir -p work_vimalter
    cd work_vimalter
    wget -q https://github.com/tennashi/vimalter/releases/download/0.1.0/vimalter_0.1.0_Linux_64-bit.tar.gz -O vimalter.tar.gz
    tar xfz vimalter.tar.gz
    mv vimalter ~/.local/bin/
    cd ..
    rm -rf work_vimalter
  EOCMD
  user node[:user]
  not_if "test -f ~/.local/bin/vimalter"
end
