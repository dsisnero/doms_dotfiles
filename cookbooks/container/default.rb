module ContainerHelper
  def container_installed_version
    case node[:platform]
    when "darwin"
      binary = "/usr/local/bin/container"
      if File.exist?(binary)
        result = run_command("#{binary} --version", error: false)
        if result.success?
          # Extract version number from output (e.g., "container version 0.7.1")
          match = result.stdout.strip.match(/(\d+\.\d+\.\d+)/)
          match ? match[1] : nil
        end
      end
    end
  end
end

::MItamae::RecipeContext.include ContainerHelper
::MItamae::ResourceContext.include ContainerHelper

node[:home]

latest_version = github_latest_version("apple/container")
installed_version = container_installed_version
MItamae.logger.info "Container installed version: #{installed_version}"
MItamae.logger.info "Latest version: #{latest_version}"
needs_update = if latest_version.nil?
  !File.exist?("/usr/local/bin/container")
else
  installed_version.nil? || version_less_than?(installed_version, latest_version)
end

case node[:platform]
when "darwin"
  if latest_version.nil?
    MItamae.logger.error "Cannot determine latest version of container. Skipping installation."
  else
    # Get the actual signed package URL (filename pattern varies by version)
    pkg_url = github_latest_asset_url("apple/container", /container.*installer-signed\.pkg$/i)

    if pkg_url.nil?
      MItamae.logger.error "Cannot find signed installer package for container #{latest_version}"
    else
      download_path = "/tmp/container-installer-signed.pkg"

      package "aria2"

      execute "download container pkg" do
        command "aria2c #{pkg_url} -d /tmp/ -o container-installer-signed.pkg"
        only_if { needs_update }
        notifies :run, "execute[install container pkg]", :immediately
      end

      execute "install container pkg" do
        command "installer -pkg #{download_path} -target /"
        user "root"
        action :nothing
        notifies :run, "execute[cleanup container pkg]", :immediately
      end

      execute "cleanup container pkg" do
        command "rm -f #{download_path}"
        action :nothing
      end
    end
  end

  # Ensure container system service is running
  execute "start container system service" do
    command "container system start"
    only_if "which container && ! container system status 2>/dev/null"
  end
end
