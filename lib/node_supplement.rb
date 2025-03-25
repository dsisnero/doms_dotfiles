# Detect if running on Windows
is_windows = ENV['OS'] == 'Windows_NT'
is_wsl = !is_windows && run_command("uname -a | grep -i Microsoft", error: false).exit_status == 0

node.reverse_merge!(
  user: ENV["SUDO_USER"] || ENV["USER"],
  is_windows: is_windows,
  is_wsl: is_wsl,
  os: 'linux' # Default fallback
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

# Add platform detection before platform_family
node.reverse_merge!(
  platform: if node[:is_windows]
              'windows'
            else
              case node[:os]
              when 'darwin'
                'macos'
              when 'linux'
                # Detect Linux distribution
                if File.exist?('/etc/os-release')
                  id = File.read('/etc/os-release')[/^ID=([^\n]+)/, 1].gsub('"', '')
                  case id
                  when 'debian', 'ubuntu', 'pop', 'linuxmint'
                    id
                  when 'arch', 'manjaro'
                    'arch'
                  when 'fedora', 'centos', 'rhel', 'amzn'
                    'fedora'
                  else
                    'linux'
                  end
                else
                  'linux'
                end
              else
                node[:os]
              end
            end
)

# Set os based on platform
node.reverse_merge!(
  os: case node[:platform]
      when 'debian', 'ubuntu', 'pop', 'linuxmint', 'arch', 'fedora'
        'linux'  # Treat Pop!_OS as generic Linux
      when 'macos', 'darwin'
        'macos'
      when 'windows'
        'windows'
      else
        node[:platform]
      end
)

# Add Windows-specific paths
node.reverse_merge!(
  
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
