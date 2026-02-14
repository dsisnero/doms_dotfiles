# SSH Server Configuration Cookbook
# Cross-platform SSH server setup with secure defaults

include_recipe "dependency.rb"

home = node[:home]
user = node[:user]
group = node[:group]

# Ensure SSH directory exists with correct permissions
directory "#{home}/.ssh" do
  owner user
  group group
  mode "700"
end

# Secure default for authorized_keys if it exists
file "#{home}/.ssh/authorized_keys" do
  owner user
  group group
  mode "600"
  action :create
  content ""
  only_if { File.exist?("#{home}/.ssh/authorized_keys") }
end

# Check if authorized_keys already has content
authorized_keys_has_content = run_command("test -s #{home}/.ssh/authorized_keys", error: false).success?

# SSH server configuration with safe defaults
ssh_server_config = node[:ssh_server] || {}

# Determine password authentication setting
# Priority: 1. Explicit node setting, 2. Auto-disable if keys present, 3. Default yes (allow initial setup)
password_authentication_setting = if ssh_server_config[:password_authentication]
  ssh_server_config[:password_authentication]
elsif authorized_keys_has_content
  "no"
else
  "yes"  # Default to yes for initial setup (allow password login)
end

case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  # Debian-based systems
  package "openssh-server"

  # Backup original config with incremental backups
  execute "backup original sshd_config with incrementing backups" do
    command incremental_backup_script("/etc/ssh/sshd_config", ".backup")
    only_if "test -f /etc/ssh/sshd_config"
    user "root"
  end

  # Apply secure configuration
  template "/etc/ssh/sshd_config" do
    user "root"
    source "templates/sshd_config.erb"
    owner "root"
    group "root"
    mode "644"
    variables(
      port: ssh_server_config[:port] || 22,
      permit_root_login: ssh_server_config[:permit_root_login] || "without-password",
      password_authentication: password_authentication_setting,
      pubkey_authentication: ssh_server_config[:pubkey_authentication] || "yes",
      permit_empty_passwords: ssh_server_config[:permit_empty_passwords] || "no",
      challenge_response_authentication: ssh_server_config[:challenge_response_authentication] || "no",
      use_pam: ssh_server_config[:use_pam] || "yes",
      allow_users: ssh_server_config[:allow_users] || user,
      x11_forwarding: ssh_server_config[:x11_forwarding] || "no",
      max_auth_tries: ssh_server_config[:max_auth_tries] || 3,
      max_sessions: ssh_server_config[:max_sessions] || 10,
      client_alive_interval: ssh_server_config[:client_alive_interval] || 300,
      client_alive_count_max: ssh_server_config[:client_alive_count_max] || 3
    )
  end

  # Restart SSH service if config changed
  service "ssh" do
    action :nothing
    subscribes :restart, "template[/etc/ssh/sshd_config]"
  end

  # Ensure SSH service is enabled and running
  service "ssh" do
    action [:enable, :start]
  end

when "redhat", "fedora", "centos", "amazon"
  # RPM-based systems
  package "openssh-server"

  # Backup original config with incremental backups
  execute "backup original sshd_config with incrementing backups" do
    command incremental_backup_script("/etc/ssh/sshd_config", ".backup")
    only_if "test -f /etc/ssh/sshd_config"
    user "root"
  end

  template "/etc/ssh/sshd_config" do
    source "templates/sshd_config.erb"
    owner "root"
    group "root"
    mode "644"
    variables(
      port: ssh_server_config[:port] || 22,
      permit_root_login: ssh_server_config[:permit_root_login] || "without-password",
      password_authentication: password_authentication_setting,
      pubkey_authentication: ssh_server_config[:pubkey_authentication] || "yes",
      permit_empty_passwords: ssh_server_config[:permit_empty_passwords] || "no",
      challenge_response_authentication: ssh_server_config[:challenge_response_authentication] || "no",
      use_pam: ssh_server_config[:use_pam] || "yes",
      allow_users: ssh_server_config[:allow_users] || user,
      x11_forwarding: ssh_server_config[:x11_forwarding] || "no",
      max_auth_tries: ssh_server_config[:max_auth_tries] || 3,
      max_sessions: ssh_server_config[:max_sessions] || 10,
      client_alive_interval: ssh_server_config[:client_alive_interval] || 300,
      client_alive_count_max: ssh_server_config[:client_alive_count_max] || 3
    )
  end

  service "sshd" do
    action :nothing
    subscribes :restart, "template[/etc/ssh/sshd_config]"
  end

  service "sshd" do
    action [:enable, :start]
  end

when "arch"
  # Arch Linux
  package "openssh"

  # Backup original config with incremental backups
  execute "backup original sshd_config with incrementing backups" do
    command incremental_backup_script("/etc/ssh/sshd_config", ".backup")
    only_if "test -f /etc/ssh/sshd_config"
    user "root"
  end

  template "/etc/ssh/sshd_config" do
    source "templates/sshd_config.erb"
    owner "root"
    group "root"
    mode "644"
    variables(
      port: ssh_server_config[:port] || 22,
      permit_root_login: ssh_server_config[:permit_root_login] || "without-password",
      password_authentication: password_authentication_setting,
      pubkey_authentication: ssh_server_config[:pubkey_authentication] || "yes",
      permit_empty_passwords: ssh_server_config[:permit_empty_passwords] || "no",
      challenge_response_authentication: ssh_server_config[:challenge_response_authentication] || "no",
      use_pam: ssh_server_config[:use_pam] || "yes",
      allow_users: ssh_server_config[:allow_users] || user,
      x11_forwarding: ssh_server_config[:x11_forwarding] || "no",
      max_auth_tries: ssh_server_config[:max_auth_tries] || 3,
      max_sessions: ssh_server_config[:max_sessions] || 10,
      client_alive_interval: ssh_server_config[:client_alive_interval] || 300,
      client_alive_count_max: ssh_server_config[:client_alive_count_max] || 3
    )
  end

  service "sshd" do
    action :nothing
    subscribes :restart, "template[/etc/ssh/sshd_config]"
  end

  service "sshd" do
    action [:enable, :start]
  end

when "darwin", "osx"
  # macOS - enable built-in SSH server (Remote Login)
  # Use launchctl to load SSH daemon plist (avoids systemsetup Full Disk Access requirement)
  execute "enable macOS ssh server via launchctl" do
    command "sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist"
    not_if "sudo launchctl list | grep -q com.openssh.sshd"
  end

  # Ensure SSH service is running
  execute "start macOS ssh server" do
    command "sudo launchctl start com.openssh.sshd"
    not_if "sudo launchctl list | grep -q '^[0-9].*com.openssh.sshd'"
  end

  # Remove problematic macOS config file that may contain unsupported options
  execute "remove problematic macOS sshd config file" do
    command "sudo rm -f /etc/ssh/sshd_config.d/100-macos.conf"
    only_if "test -f /etc/ssh/sshd_config.d/100-macos.conf"
    user user
  end

  # Backup original config with incremental backups
  execute "backup original sshd_config with incrementing backups" do
    command incremental_backup_script("/etc/ssh/sshd_config", ".backup")
    only_if "test -f /etc/ssh/sshd_config"
    user "root"
  end

  # Configure sshd_config on macOS - use temp file pattern to avoid permission issues
  temp_config_path = "#{home}/.sshd_config.tmp"

  # Create temporary config file in user's home directory using template
  template temp_config_path do
    source "templates/sshd_config.erb"
    owner user
    group group
    mode "600"
    variables(
      port: ssh_server_config[:port] || 22,
      permit_root_login: ssh_server_config[:permit_root_login] || "without-password",
      password_authentication: password_authentication_setting,
      pubkey_authentication: ssh_server_config[:pubkey_authentication] || "yes",
      permit_empty_passwords: ssh_server_config[:permit_empty_passwords] || "no",
      challenge_response_authentication: ssh_server_config[:challenge_response_authentication] || "no",
      use_pam: ssh_server_config[:use_pam] || "yes",
      allow_users: ssh_server_config[:allow_users] || user,
      x11_forwarding: ssh_server_config[:x11_forwarding] || "no",
      max_auth_tries: ssh_server_config[:max_auth_tries] || 3,
      max_sessions: ssh_server_config[:max_sessions] || 10,
      client_alive_interval: ssh_server_config[:client_alive_interval] || 300,
      client_alive_count_max: ssh_server_config[:client_alive_count_max] || 3
    )
  end

  # Copy temporary file to system location with sudo
  execute "copy sshd_config to system location" do
    command "sudo cp -p #{temp_config_path} /etc/ssh/sshd_config && sudo chmod 644 /etc/ssh/sshd_config"
    user user
    not_if "diff -q #{temp_config_path} /etc/ssh/sshd_config >/dev/null 2>&1"
  end

  # Restart sshd on macOS if config changed
  execute "restart macOS sshd" do
    command "sudo launchctl stop com.openssh.sshd && sudo launchctl start com.openssh.sshd"
    action :nothing
    subscribes :run, "execute[copy sshd_config to system location]"
  end

when "windows"
  # Skip Windows SSH server installation if running in WSL (Windows Subsystem for Linux)
  if wsl?
    log "Skipping Windows SSH server installation in WSL environment"
  else
    # Windows - Install OpenSSH Server feature
    # Note: Requires Windows 10 1809+ or Windows Server 2019+
    execute "install openssh server" do
      command <<-EOH
        powershell -Command "
          # Check if OpenSSH Server is already installed
          $feature = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
          if ($feature.State -ne 'Installed') {
            # Install the OpenSSH Server
            Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
          }
        "
      EOH
      not_if <<-EOH
        powershell -Command "
          $feature = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
          $feature.State -eq 'Installed'
        "
      EOH
    end

    # Start and configure SSH service on Windows
    execute "start sshd service" do
      command <<-EOH
        powershell -Command "
          Start-Service sshd
          Set-Service -Name sshd -StartupType Automatic
        "
      EOH
      not_if <<-EOH
        powershell -Command "
          (Get-Service sshd).Status -eq 'Running'
        "
      EOH
    end

    # Backup original config on Windows with incremental backups
    execute "backup sshd_config on Windows" do
      command <<-EOH
        powershell -Command "
          $configPath = 'C:\\ProgramData\\ssh\\sshd_config'
          if (Test-Path $configPath) {
            $backupPath = $configPath + '.backup'
            $i = 1
            while (Test-Path $backupPath) {
              $i++
              $backupPath = $configPath + '.backup.' + $i
            }
            Copy-Item $configPath $backupPath -Force
          }
        "
      EOH
      not_if <<-EOH
        powershell -Command "
          !(Test-Path 'C:\\ProgramData\\ssh\\sshd_config')
        "
      EOH
    end

    # Configure sshd_config on Windows
    # Windows SSH config is at: C:\ProgramData\ssh\sshd_config
    template "C:/ProgramData/ssh/sshd_config" do
      source "templates/sshd_config.erb"
      variables(
        port: ssh_server_config[:port] || 22,
        permit_root_login: ssh_server_config[:permit_root_login] || "without-password",
        password_authentication: password_authentication_setting,
        pubkey_authentication: ssh_server_config[:pubkey_authentication] || "yes",
        permit_empty_passwords: ssh_server_config[:permit_empty_passwords] || "no",
        challenge_response_authentication: ssh_server_config[:challenge_response_authentication] || "no",
        use_pam: ssh_server_config[:use_pam] || "yes",
        allow_users: ssh_server_config[:allow_users] || user,
        x11_forwarding: ssh_server_config[:x11_forwarding] || "no",
        max_auth_tries: ssh_server_config[:max_auth_tries] || 3,
        max_sessions: ssh_server_config[:max_sessions] || 10,
        client_alive_interval: ssh_server_config[:client_alive_interval] || 300,
        client_alive_count_max: ssh_server_config[:client_alive_count_max] || 3
      )
    end

    # Restart SSH service on Windows if config changed
    execute "restart sshd service if config changed" do
      command "powershell -Command \"Restart-Service sshd\""
      action :nothing
      subscribes :run, "template[C:/ProgramData/ssh/sshd_config]"
    end
  end

else
  log "SSH server not implemented for platform: #{node[:platform]}"
end

# SSH Key Management
# Optionally add SSH public keys to authorized_keys
if ssh_server_config[:authorized_keys]
  # Create authorized_keys file with specified keys
  file "#{home}/.ssh/authorized_keys" do
    owner user
    group group
    mode "600"
    content ssh_server_config[:authorized_keys].join("\n")
  end
end

# Optionally fetch SSH keys from GitHub
if ssh_server_config[:github_user]
  execute "fetch ssh keys from github" do
    command "curl -s https://github.com/#{ssh_server_config[:github_user]}.keys >> #{home}/.ssh/authorized_keys"
    not_if "grep -q '#{ssh_server_config[:github_user]}' #{home}/.ssh/authorized_keys 2>/dev/null"
    user user
  end
end
