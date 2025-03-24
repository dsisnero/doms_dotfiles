if windows? && !wsl?
  # Set persistent environment variables
  execute "Set XDG variables" do
    command <<-PS1
    [Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", "#{node[:config_home]}", "User")
    [Environment]::SetEnvironmentVariable("XDG_DATA_HOME", "#{node[:data_home]}", "User")
    [Environment]::SetEnvironmentVariable("XDG_CACHE_HOME", "#{node[:cache_home]}", "User")
    PS1
    interpreter "powershell"
    not_if "[Environment]::GetEnvironmentVariable('XDG_CONFIG_HOME', 'User')"
  end

  # Add to system PATH if config/bin exists
  execute "Add XDG bin to PATH" do
    command <<-PS1
    $binPath = "#{node[:config_home]}/bin"
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not $currentPath.Contains($binPath)) {
      [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$binPath", "User")
    }
    PS1
    interpreter "powershell"
    only_if "Test-Path -Path \"#{node[:config_home]}/bin\""
  end
end
