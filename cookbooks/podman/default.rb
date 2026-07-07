# Install podman container runtime
include_recipe "dependency.rb"

user = node[:user]
home = node[:home]
local_bin = "#{home}/.local/bin"

case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  package "podman"
  package "podman-compose"

  version = github_latest_version("containers/podman-tui")
  release_url = "https://github.com/containers/podman-tui/releases/download/v#{version}/podman-tui-release-linux_amd64.zip"
  zip_path = "#{node[:cache_home]}/podman-tui-#{version}.zip"
  extract_dir = "#{node[:cache_home]}/podman-tui-extract"

  execute "download podman-tui" do
    user user
    command <<~EOCMD
      mkdir -p #{extract_dir}
      for i in {1..5}; do
        curl -fL -o #{zip_path} #{release_url} && break || sleep 2
      done
      unzip -o #{zip_path} -d #{extract_dir}
      cp #{extract_dir}/podman-tui #{local_bin}/podman-tui
      chmod +x #{local_bin}/podman-tui
      rm -rf #{zip_path} #{extract_dir}
    EOCMD
    not_if { File.exist?("#{local_bin}/podman-tui") }
  end

when "osx", "darwin"
  package "podman"
  package "podman-compose"
  package "podman-tui"

  # Note: On macOS, podman requires a Linux VM
  # Users can start it manually with `podman machine init` and `podman machine start`
  # Or install podman-desktop cask for GUI management

when "arch"
  package "podman"
  package "podman-compose"
  package "podman-tui"

when "windows"
  # Windows installation would require WSL2 or native Windows version
  log "Podman for Windows not implemented in this cookbook"
end
