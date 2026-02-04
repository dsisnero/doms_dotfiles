module RpiImagerHelper
  def rpi_imager_installed_version
    begin
      case node[:platform]
      when "debian", "ubuntu", "mint", "pop"
        # Check if AppImage exists and get its version
        appimage_path = "#{node[:home]}/.local/bin/rpi-imager"
        if File.exist?(appimage_path)
          # Try to get version from AppImage
          result = run_command("#{appimage_path} --version 2>/dev/null", error: false)
          if result.success?
            # Extract version from output, e.g., "Raspberry Pi Imager v1.9.6"
            match = result.stdout.match(/v(\d+\.\d+\.\d+)/)
            return match[1] if match
          end
        end
        # Also check snap version
        result = run_command("snap list rpi-imager 2>/dev/null | grep rpi-imager", error: false)
        if result.success?
          match = result.stdout.match(/rpi-imager\s+\S+\s+(\d+\.\d+\.\d+)/)
          return match[1] if match
        end
      when "darwin"
        # Check Homebrew version
        result = run_command("brew list --versions raspberry-pi-imager 2>/dev/null", error: false)
        if result.success?
          match = result.stdout.match(/raspberry-pi-imager\s+(\d+\.\d+\.\d+)/)
          return match[1] if match
        end
      end
    rescue => e
      MItamae.logger.warn "Failed to get installed RPi Imager version: #{e.message}"
    end
    nil
  end

  def rpi_imager_latest_appimage_info
    begin
      # Get the downloads page and parse for latest AppImage with retries
      max_retries = 3
      retry_count = 0

      while retry_count < max_retries
        # Fetch the HTML page
        cmd = "curl -s https://downloads.raspberrypi.com/imager/"
        result = run_command(cmd, error: false)

        if result.success?
          html = result.stdout
          appimages = []

          # Extract all AppImage filenames from href attributes
          # Pattern 1: imager_X.Y.Z_amd64.AppImage (new pattern)
          html.scan(/href="(imager_\d+\.\d+\.\d+_amd64\.AppImage)"/) do |match|
            filename = match[0]
            version_match = filename.match(/imager_(\d+\.\d+\.\d+)_amd64\.AppImage/)
            if version_match
              appimages << {version: version_match[1], filename: filename}
            end
          end

          # Pattern 2: Raspberry_Pi_Imager-X.Y.Z-x86_64.AppImage (old pattern)
          html.scan(/href="(Raspberry_Pi_Imager-\d+\.\d+\.\d+-x86_64\.AppImage)"/) do |match|
            filename = match[0]
            version_match = filename.match(/Raspberry_Pi_Imager-(\d+\.\d+\.\d+)-x86_64\.AppImage/)
            if version_match
              appimages << {version: version_match[1], filename: filename}
            end
          end

          # Return the highest version
          unless appimages.empty?
            highest = appimages.first
            appimages.each do |appimage|
              if version_less_than?(highest[:version], appimage[:version])
                highest = appimage
              end
            end
            return highest
          end
        end

        retry_count += 1
        sleep 2 if retry_count < max_retries
      end
    rescue => e
      MItamae.logger.warn "Failed to get latest RPi Imager version: #{e.message}"
    end
    nil
  end

  def rpi_imager_latest_version
    info = rpi_imager_latest_appimage_info
    info ? info[:version] : nil
  end

  def rpi_imager_latest_appimage_url(version = nil)
    info = rpi_imager_latest_appimage_info
    return nil unless info

    filename = info[:filename]
    "https://downloads.raspberrypi.com/imager/#{filename}"
  end
end

::MItamae::RecipeContext.include RpiImagerHelper
::MItamae::ResourceContext.include RpiImagerHelper

# Install rpi-imager using latest AppImage from downloads page
case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  home = node[:home]
  user = node[:user]
  local_bin = "#{home}/.local/bin"
  cache_dir = "#{home}/.cache/rpi-imager"
  appimage_name = "rpi-imager"
  appimage_path = "#{local_bin}/#{appimage_name}"

  directory local_bin do
    owner user
    group node[:group] || user
    mode "755"
  end

  directory cache_dir do
    owner user
    group node[:group] || user
    mode "755"
  end

  latest_info = rpi_imager_latest_appimage_info
  latest_version = latest_info ? latest_info[:version] : nil
  installed_version = rpi_imager_installed_version

  MItamae.logger.info "RPi Imager installed version: #{installed_version}"
  MItamae.logger.info "RPi Imager latest version: #{latest_version}"

  needs_update = if latest_version.nil?
    !File.exist?(appimage_path)
  else
    installed_version.nil? || version_less_than?(installed_version, latest_version)
  end

  if needs_update && latest_info
    download_url = "https://downloads.raspberrypi.com/imager/#{latest_info[:filename]}"
    download_path = "#{cache_dir}/#{appimage_name}-#{latest_version}.AppImage"

    http_request download_path do
      url download_url
      path download_path
      user user
      notifies :run, "execute[make rpi-imager executable]"
    end

    execute "make rpi-imager executable" do
      action :nothing
      command "chmod +x #{download_path}"
      user user
      notifies :run, "execute[install rpi-imager]"
    end

    execute "install rpi-imager" do
      action :nothing
      command "mv -f #{download_path} #{appimage_path}"
      user user
    end
  else
    # Ensure existing AppImage is executable
    execute "ensure rpi-imager executable" do
      command "chmod +x #{appimage_path}"
      only_if "test -f #{appimage_path}"
      user user
    end
  end

  # Remove old snap installation if present
  execute "remove old snap rpi-imager" do
    command "snap remove rpi-imager --purge"
    only_if "snap list | grep -q rpi-imager"
    user "root"
  end

when "osx", "darwin"
  package "raspberry-pi-imager"

when "windows"
  # Windows installation would require downloading the installer
  # Not implemented in this cookbook
  log "Raspberry Pi Imager for Windows not implemented in this cookbook"
end
