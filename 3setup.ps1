$ErrorActionPreference = 'Stop'
$windows_home = 'C:\windows_home'
mkdir -Force -p ${HOME}/repos/github.com/dsisnero/
git clone https://github.com/dsisnero/doms_dotfiles.git ${HOME}/repos/github.com/dsisnero/doms_dotfiles

# symlink
mkdir -Force -p "$HOME\AppData\Local\Microsoft\Windows Terminal"
mkdir -Force -p "$HOME\Documents\PowerShell"
mkdir -Force -p "$HOME\.config"

New-Item -Value "$windows_home\repos\github.com\dsisnero\doms_dotfiles\config\WindowsTerminal\settings.json" -Path "$HOME\AppData\Local\Microsoft\Windows Terminal" -Name settings.json -ItemType SymbolicLink
New-Item -Value "$windows_home\repos\github.com\dsisnero\doms_dotfiles\config\Microsoft.PowerShell_profile.ps1" -Path "$HOME\Documents\PowerShell" -Name Microsoft.PowerShell_profile.ps1 -ItemType SymbolicLink
New-Item -Value "$windows_home\repos\github.com\dsisnero\doms_dotfiles\config\.config\git\config" -Path "$windows_home\.config\git" -Name config -ItemType SymbolicLink
New-Item -Value "$windows_home\repos\github.com\dsisnero\doms_dotfiles\config\.config\wezterm" -Path "$windows_home\.config\" -Name wezterm -ItemType SymbolicLink
New-Item -Value "$windows_home\repos\github.com\dsisnero\doms_dotfiles\config\.config\helix\config.toml" -Path "$windows_home\.config\helix" -Name config.toml -ItemType SymbolicLink
New-Item -Value "$windows_home\repos\github.com\dsisnero\doms_dotfiles\config\.config\helix\languages.toml" -Path "$windows_home\.config\helix" -Name languages.toml -ItemType SymbolicLink

# wingetデデキルヨ
# Storeアプリインストールしてちょ
# echo '* Please install store apps.'
# echo '* Launch WindowsStore app.'
# Start-Process shell:AppsFolder\Microsoft.WindowsStore_8wekyb3d8bbwe!App
