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
package "container"
# package "z"  replaced by zoxide
# cask
# package "dropbox"
package "vlc"
package "virtualbox"
package "vagrant"
include_cookbook "java"
package "google-drive"
package "logi-options+"
package "mas"
define :mas, id: nil, user: nil, not_if_: nil, not_if: nil, only_if_: nil, only_if: nil do
  name_ = params[:name]
  id = params[:id]
  user_ = params[:user] || node[:user]
  params[:not_if] || params[:not_if_]
  params[:only_if] || params[:only_if_]

  execute "install #{name_}" do
    user user_ unless user_.nil?
    command <<EOCMD
       mas install #{id}
EOCMD
  end
end

apps = [
  {id: "1091189122", name: "Bear"},
  {id: "682658836", name: "GarageBand"},
  {id: "408981434", name: "iMovie"},
  {id: "6444602274", name: "Ivory"},
  {id: "409183694", name: "Keynote"},
  {id: "409203825", name: "Numbers"},
  {id: "409201541", name: "Pages"}
]

apps.each do |app|
  mas app[:name] do
    id app[:id]
  end
end

# package "caskroom/cask/android-file-transfer"
# package "caskroom/cask/1password"
# package "caskroom/cask/buttercup"
# package "caskroom/cask/skype"
# package "caskroom/cask/steam"
# package "caskroom/cask/cooviewer"
# package "caskroom/cask/iterm2"
# package "caskroom/cask/dash"
# package "caskroom/cask/android-studio"
