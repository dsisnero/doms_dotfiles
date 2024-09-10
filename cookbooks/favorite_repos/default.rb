include_cookbook "dotfiles"
include_cookbook "ghq"

repos = %w[
  bundai223/dotfiles
  fujiwara/isucon11-f
  itamae-kitchen/mitamae
  AstroNvim/astrocommunity
]
repos.each { |name| get_repo name.chomp }

pip_pkgs = %w[
  powerline-status
  powerline-gitstatus
  python-language-server
]
%w[pip pip3].each do |pip|
  pip_pkgs.each do |pkg|
    execute ". /etc/profile.d/asdf.sh; #{pip} install #{pkg}" do
      user node[:user]
      only_if ". /etc/profile.d/asdf.sh; which #{pip}>/dev/null"
    end
  end
end

package "fontforge"
