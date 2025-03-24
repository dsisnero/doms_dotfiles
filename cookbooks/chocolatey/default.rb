# Install Chocolatey package manager for Windows
if windows? && !wsl?
  execute 'Install Chocolatey' do
    command <<-CMD
      Set-ExecutionPolicy Bypass -Scope Process -Force
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
      iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    CMD
    not_if 'if (Get-Command choco -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }'
    interpreter 'powershell'
  end
end
