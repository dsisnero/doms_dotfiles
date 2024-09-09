include_recipe "dependency.rb"

case node[:platform]
when "arch"
  raise NotImplementedError
when "osx", "darwin"
  raise NotImplementedError
when "fedora", "redhat", "amazon"
  raise NotImplementedError

when "debian", "ubuntu", "mint"
  user = node["user"]

  version = github_latest_version("git-ecosystem/git-credential-manager")

  deb_url = "https://github.com/git-ecosystem/git-credential-manager/releases/download/v#{version}/gcm-linux_amd64.#{version}.deb"

  deb_path = "/tmp/gcm-linux_amd64-#{version}.deb"

  http_request "download gcm deb" do
    url deb_url
    path deb_path
    owner user
    not_if do
      installed_version = begin
        `git-credential-manager --version`.strip
      rescue
        nil
      end
      installed_version == version
    end
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
