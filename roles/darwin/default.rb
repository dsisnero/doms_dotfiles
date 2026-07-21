execute "brew update"
execute "brew upgrade"

include_role "base"

# osx
package "wget"
package "aria2"
package "coreutils"
package "findutils"
package "luajit"
package "lua"
package "git"
package "reattach-to-user-namespace"
package "netnewswire"
package "open-sp"
package "basictex"
package "texlive"
package "gemini-cli"
# package "z"  replaced by zoxide
# cask
# package "dropbox"
include_cookbook "container"
include_cookbook "rpi_imager"
include_cookbook "llama.cpp"

package "vlc"
package "virtualbox"
# package "vagrant" # handled by cookbooks/vagrant
package "google-drive"
package "logi-options+"
package "mas"
include_definition "mas"

# apps.each do |app|
#   mas app[:name] do
#     id app[:id]
#   end
# end

# package "caskroom/cask/android-file-transfer"
# package "caskroom/cask/1password"
# package "caskroom/cask/buttercup"
# package "caskroom/cask/skype"
# package "caskroom/cask/steam"
# package "caskroom/cask/cooviewer"
# package "caskroom/cask/iterm2"
# package "caskroom/cask/dash"
# package "caskroom/cask/android-studio"
include_role "desktop"
