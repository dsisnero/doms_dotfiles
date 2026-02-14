case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  # Install Homebridge via official APT repository (works on Raspberry Pi/Raspbian)
  # Ensure curl and gpg are available
  package "curl"
  package "gpg"

  # Add Homebridge GPG key and repository (idempotent)
  execute "add homebridge gpg key" do
    command "curl -sSfL https://repo.homebridge.io/KEY.gpg | gpg --dearmor | tee /usr/share/keyrings/homebridge.gpg > /dev/null"
    user "root"
    not_if "test -f /usr/share/keyrings/homebridge.gpg"
  end

  execute "add homebridge apt repository" do
    command 'echo "deb [signed-by=/usr/share/keyrings/homebridge.gpg] https://repo.homebridge.io stable main" | tee /etc/apt/sources.list.d/homebridge.list > /dev/null'
    user "root"
    not_if "test -f /etc/apt/sources.list.d/homebridge.list"
  end

  # Update package list after adding repository
  execute "apt update after adding homebridge repo" do
    command "apt update"
    user "root"
    subscribes :run, "execute[add homebridge apt repository]"
    action :nothing
  end

  # Install Homebridge package
  package "homebridge" do
    action :install
  end

when "darwin", "osx"
  # macOS - install via npm (Homebrew method also available)
  execute "install homebridge via npm" do
    command "npm install -g --unsafe-perm homebridge homebridge-config-ui-x"
    user node[:user]
    not_if { run_command("which homebridge", error: false).exit_status == 0 }
  end

when "redhat", "fedora", "centos", "amazon"
  # RPM-based systems - not implemented yet
  log "Homebridge installation not implemented for #{node[:platform]}"

when "arch"
  # Arch Linux - install via AUR or other methods
  log "Homebridge installation not implemented for #{node[:platform]}"

when "windows"
  # Windows - not implemented
  log "Homebridge installation not implemented for #{node[:platform]}"

else
  log "Homebridge installation not implemented for platform: #{node[:platform]}"
end
