if node[:family] == "windows"
  home = ENV["USERPROFILE"].tr("\\", "/") # Unix-style
  program_files = ENV["ProgramFiles"].tr("\\", "/")
  app_data = ENV["APPDATA"].tr("\\", "/")

  # Get Windows version information if on Windows
  win_version = run_command("powershell -Command \"(Get-CimInstance Win32_OperatingSystem).Caption\"", error: false).stdout.strip
  win_build = run_command("powershell -Command \"(Get-CimInstance Win32_OperatingSystem).BuildNumber\"", error: false).stdout.strip

  node.reverse_merge!(
    home: home,
    program_files: program_files,
    app_data: app_data,
    win_version: win_version,
    win_build: win_build
  )

end
