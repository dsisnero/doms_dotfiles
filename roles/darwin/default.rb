execute "brew update"
execute "brew upgrade"

include_role "base"

# osx
package "wget"
package "coreutils"
package "findutils"
package "luajit"
package "lua"
package "git"
package "mercurial"
package "z"
package "the_silver_searcher"
package "reattach-to-user-namespace"
# cask
package "caskroom/cask/android-file-transfer"
package "caskroom/cask/1password"
package "caskroom/cask/buttercup"
package "caskroom/cask/dropbox"
package "caskroom/cask/skype"
package "caskroom/cask/steam"
package "caskroom/cask/cooviewer"
package "caskroom/cask/vlc"
package "caskroom/cask/iterm2"
package "caskroom/cask/dash"
package "caskroom/cask/android-studio"
package "caskroom/cask/virtualbox"
package "caskroom/cask/vagrant"
package "caskroom/cask/java"
