#Requires -Version 5

# enable wsl2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# wget https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
# install wsl_update_x64.msi

# nankano policy
Set-ExecutionPolicy RemoteSigned -scope CurrentUser

wsl --set-default-version 2

# install scoop
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

$known_buckets = @(
  'extras',
  'nerd-fonts'
)
$unknown_buckets = @(
  @{name = 'dsisnero'; url = 'https://github.com/dsisnero/scoop-for-jp'},
  @{name = 'anurse'; url = 'https://github.com/anurse/scoop-bucket'}, # 
  @{name = 'sh4869221b'; url = 'https://github.com/sh4869221b/scoop-bucket'}, # virtualbox
  @{name = 'wangzq'; url = 'https://github.com/wangzq/scoop-bucket'}
)
$apps = @(
  'firacode',
  'ghq',
  'brave',
  'vivaldi',
  '7zip',
  'bitwarden',
  'screentogif',
  'screentogif',
  'zeal',
  'ctrl2cap',
  # 'screenpresso',
  # 'screeninfo', # https://v2.rakuchinn.jp/
  'pwsh',
  'sudo',
  'vim',
  'neovim',
  'vcredist',
  'obsidian',
  'wezterm'
)
  
# add bucekts
scoop install git # bucketインストールにはgit必要
$known_buckets | % { scoop bucket add $_ }
$unknown_buckets | % { scoop bucket add $_['name'] $_['url'] }

# install app
$apps | % { scoop install $_ }

# install powershell module
Install-Module posh-git -Scope CurrentUser
Install-Module oh-my-posh -Scope CurrentUser
Install-Module -Name PSReadLine -RequiredVersion 2.1.0
Install-Module ZLocation -Scope CurrentUser

ssh-keygen -t ed25519 -C "dsisnero@gmail.com"
mkdir -Force -p ${HOME}/repos/github.com/dsisnero/
git clone https://github.com/dsisnero/doms_dotfiles.git ${HOME}/repos/github.com/dsisnero/doms_dotfiles

# symlink
mkdir -Force -p "$HOME\AppData\Local\Microsoft\Windows Terminal"
mkdir -Force -p "$HOME\Documents\PowerShell"
mkdir -Force -p "$HOME\.config"

New-Item -Value "$HOME\repos\github.com\dsisnero\dotfiles\config\WindowsTerminal\settings.json" -Path "$HOME\AppData\Local\Microsoft\Windows Terminal" -Name settings.json -ItemType SymbolicLink
New-Item -Value "$HOME\repos\github.com\dsisnero\dotfiles\config\Microsoft.PowerShell_profile.ps1" -Path "$HOME\Documents\PowerShell" -Name Microsoft.PowerShell_profile.ps1 -ItemType SymbolicLink
New-Item -Value "$HOME\repos\github.com\dsisnero\dotfiles\config\.gitconfig" -Path "$HOME\" -Name .gitconfig -ItemType SymbolicLink
New-Item -Value "$HOME\repos\github.com\dsisnero\dotfiles\config\.config\wezterm" -Path "$HOME\.config\" -Name wezterm -ItemType SymbolicLink

# Storeアプリインストールしてちょ
echo '* Please install store apps.'
echo '* Launch WindowsStore app.'
Start-Process shell:AppsFolder\Microsoft.WindowsStore_8wekyb3d8bbwe!App
