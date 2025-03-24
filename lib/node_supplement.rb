# Detect if running on Windows
is_windows = ENV['OS'] == 'Windows_NT'
is_wsl = !is_windows && run_command("uname -a | grep -i Microsoft", error: false).exit_status == 0

node.reverse_merge!(
  user: ENV["SUDO_USER"] || ENV["USER"],
  is_windows: is_windows,
  is_wsl: is_wsl
)

# In some Linux distribution, `sudo -E` doesn't preserve environment variables.
# Alternatively, we use `node[:home]`.
node.reverse_merge!(
  home: if node[:is_windows]
          ENV['USERPROFILE'].gsub('\\', '/') # Unix-style path
        else
          run_command("sudo -u #{node[:user]} printenv HOME", error: false).stdout.strip
        end
)

node.reverse_merge!(
  arch: run_command("uname -m", error: false).stdout.strip
)

node.reverse_merge!(
  os: run_command("uname", error: false).stdout.strip.downcase
)

# Add Windows-specific paths and platform family
node.reverse_merge!(
  platform_family: if node[:is_windows]
                     'windows'
                   else
                     case node[:platform]
                     when 'arch', 'debian', 'ubuntu', 'mint', 'fedora', 'pop'
                       'linux'
                     when 'darwin', 'osx'
                       'macos'
                     else
                       node[:platform]
                     end
                   end,
  
  # Windows-specific paths if on Windows
  program_files: node[:is_windows] ? (ENV['ProgramFiles'] ? ENV['ProgramFiles'].gsub('\\', '/') : '/Program Files') : nil,
  appdata: node[:is_windows] ? (ENV['APPDATA'] ? ENV['APPDATA'].gsub('\\', '/') : "#{node[:home]}/AppData/Roaming") : nil
)

# Get Windows version information if on Windows
if node[:is_windows]
  begin
    win_version = run_command("powershell -Command \"(Get-CimInstance Win32_OperatingSystem).Caption\"", error: false).stdout.strip
    win_build = run_command("powershell -Command \"(Get-CimInstance Win32_OperatingSystem).BuildNumber\"", error: false).stdout.strip
    
    node.reverse_merge!(
      os_version: win_version,
      os_build: win_build
    )
  rescue => e
    # Log error but continue
  end
end
