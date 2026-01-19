include_recipe "dependency.rb"

case node[:platform]
when "arch"
  raise NotImplementedError
when "osx", "darwin"
  package "git-credential-manager"
when "fedora", "redhat", "amazon"
  raise NotImplementedError

when "debian", "ubuntu", "mint", "pop"
  user = node["user"]

  version = github_latest_version("git-ecosystem/git-credential-manager")

  deb_url = "https://github.com/git-ecosystem/git-credential-manager/releases/download/v#{version}/gcm-linux_amd64.#{version}.deb"

  deb_path = "/tmp/gcm-linux_amd64-#{version}.deb"

  execute "download gcm deb" do
    command <<~EOCMD
      for i in {1..5}; do
        curl -fL -o #{deb_path} #{deb_url} && break || sleep 2
      done
    EOCMD
    user "root"
    not_if do
      installed_version = begin
        `git-credential-manager --version`.strip
      rescue
        nil
      end
      installed_version == version
    end
  end

  file deb_path do
    owner user
    only_if { File.exist?(deb_path) }
  end

  execute "install git-credential-manager" do
    command <<~EOCMD
      sudo dpkg -i #{deb_path}
      rm -rf #{deb_path}
    EOCMD
  end

when "opensuse"
  raise NotImplementedError
else
  raise NotImplementedError
end
