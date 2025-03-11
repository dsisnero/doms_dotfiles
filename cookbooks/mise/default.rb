include_recipe "dependency.rb"

user_ = node[:user]
home_ = node[:home]

case node[:platform]
when "debian", "mint", "ubuntu"

  # Stop packagekit to avoid lock conflicts
  service "packagekit" do
    action [:stop, :disable]
    only_if "systemctl list-unit-files | grep -q packagekit.service"
  end

  # Clean up any stale locks
  execute "cleanup apt locks" do
    command "sudo rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock*"
    only_if "test -f /var/lib/apt/lists/lock || test -f /var/lib/dpkg/lock"
  end

  execute "install mise" do
    command <<~EOCMD
      wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg
      echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
    EOCMD
    not_if "test -f /etc/apt/sources.list.d/mise.list"
  end

  # Deduplicate repository entries
  execute "deduplicate-sources" do
    command <<~EOCMD
      # Remove duplicate entries if they exist
      if [ $(grep -c "mise.jdx.dev" /etc/apt/sources.list.d/mise.list 2>/dev/null || echo 0) -gt 1 ]; then
        echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | \
          sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
      fi
    EOCMD
    only_if "test -f /etc/apt/sources.list.d/mise.list"
  end

  # Update with lock handling
  execute "update apt" do
    command <<~EOCMD
      while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        echo "Waiting for apt lock..."
        sleep 1
      done
      sudo apt-get update -o Acquire::Retries=3 -o APT::Get::Always-Include-Phased-Updates=false
    EOCMD
  end

  package "mise"

  file "#{home_}/.bashrc" do
    action :edit
    block do |content|
      content << %[eval "$(mise activate bash)"]
    end
    not_if %(grep 'mise activate' #{home_}/.bashrc)
  end

  file "#{home_}/.zshrc" do
    action :edit
    block do |content|
      content << %[eval "$(mise activate zsh)"]
    end
    not_if %(grep 'mise activate' #{home_}/.zshrc)
  end

  fish_config_dir = "#{home_}/.config/fish"
  directory fish_config_dir do
    user user_
    group user_
    mode "755"
    mkdir_p true  # MItamae's proper recursive directory creation parameter
    not_if { File.exist?(fish_config_dir) }
  end

  fish_config = "#{home_}/.config/fish/config.fish"

  file fish_config do
    action :edit
    block do |content|
      content << %(mise activate fish | source)
    end
    not_if %(grep 'mise activate' #{fish_config})
  end

when "fedora", "redhat", "amazon"

when "osx", "darwin"
end
