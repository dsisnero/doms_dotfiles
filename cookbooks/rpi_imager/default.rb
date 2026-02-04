module RpiImagerHelper
  def rpi_imager_installed_version
    begin
      case node[:platform]
      when "debian", "ubuntu", "mint", "pop"
        # Check dpkg for .deb installation first
        result = run_command("dpkg -l | grep -i rpi-imager", error: false)
        if result.success?
          match = result.stdout.match(/rpi-imager\s+\S+\s+\S+\s+(\d+\.\d+\.\d+)/)
          return match[1] if match
        end
        # Check if AppImage exists and get its version
        appimage_path = File.join(node[:user_bin], "rpi-imager")
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
    info = rpi_imager_best_package_info
    info ? info[:version] : nil
  end

  def rpi_imager_latest_appimage_url(version = nil)
    info = rpi_imager_latest_appimage_info
    return nil unless info

    filename = info[:filename]
    "https://downloads.raspberrypi.com/imager/#{filename}"
  end

  def rpi_imager_latest_deb_info
    begin
      # Get the downloads page and parse for latest .deb with retries
      max_retries = 3
      retry_count = 0

      while retry_count < max_retries
        # Fetch the HTML page
        cmd = "curl -s https://downloads.raspberrypi.com/imager/"
        result = run_command(cmd, error: false)

        if result.success?
          html = result.stdout
          debs = []

          # Extract all .deb filenames from href attributes
          # Pattern: imager_X.Y.Z_amd64.deb
          html.scan(/href="(imager_\d+\.\d+(?:\.\d+)?_amd64\.deb)"/) do |match|
            filename = match[0]
            version_match = filename.match(/imager_(\d+\.\d+(?:\.\d+)?)_amd64\.deb/)
            if version_match
              debs << {version: version_match[1], filename: filename}
            end
          end

          # Return the highest version
          unless debs.empty?
            highest = debs.first
            debs.each do |deb|
              if version_less_than?(highest[:version], deb[:version])
                highest = deb
              end
            end
            return highest
          end
        end

        retry_count += 1
        sleep 2 if retry_count < max_retries
      end
    rescue => e
      MItamae.logger.warn "Failed to get latest RPi Imager .deb version: #{e.message}"
    end
    nil
  end

  def rpi_imager_available_packages
    begin
      # Get the downloads page and parse for all imager packages with retries
      max_retries = 3
      retry_count = 0

      while retry_count < max_retries
        # Fetch the HTML page
        cmd = "curl -s https://downloads.raspberrypi.com/imager/"
        result = run_command(cmd, error: false)

        if result.success?
          html = result.stdout
          packages = []

          # Extract all imager filenames from href attributes
          # Patterns:
          # - imager_X.Y.Z_amd64.deb
          # - imager_X.Y.Z_amd64.AppImage
          # - imager_X.Y.Z.dmg (macOS)
          # - imager_X.Y.Z.exe (Windows)
          # - Raspberry_Pi_Imager-X.Y.Z-x86_64.AppImage (old pattern)
          # Ignore .sig files and files without version numbers

          # New pattern: imager_X.Y.Z_amd64.ext or imager_X.Y.Z.ext
          html.scan(/href="(imager_\d+\.\d+(?:\.\d+)?(?:_amd64)?\.(?:deb|AppImage|dmg|exe))"/) do |match|
            filename = match[0]
            # Extract version and type
            if filename =~ /imager_(\d+\.\d+(?:\.\d+)?)(?:_amd64)?\.(deb|AppImage|dmg|exe)/
              version = $1
              type = $2
              packages << {version: version, type: type, filename: filename}
            end
          end

          # Old pattern: Raspberry_Pi_Imager-X.Y.Z-x86_64.AppImage
          html.scan(/href="(Raspberry_Pi_Imager-\d+\.\d+\.\d+-x86_64\.AppImage)"/) do |match|
            filename = match[0]
            if filename =~ /Raspberry_Pi_Imager-(\d+\.\d+\.\d+)-x86_64\.AppImage/
              version = $1
              packages << {version: version, type: "AppImage", filename: filename}
            end
          end

          return packages unless packages.empty?
        end

        retry_count += 1
        sleep 2 if retry_count < max_retries
      end
    rescue => e
      MItamae.logger.warn "Failed to get available RPi Imager packages: #{e.message}"
    end
    []
  end

  def rpi_imager_best_package_info
    packages = rpi_imager_available_packages
    return nil if packages.empty?

    # Group packages by version
    versions = {}
    packages.each do |pkg|
      version = pkg[:version]
      versions[version] ||= {deb: nil, appimage: nil, dmg: nil, exe: nil}
      case pkg[:type]
      when "deb"
        versions[version][:deb] = pkg
      when "AppImage"
        versions[version][:appimage] = pkg
      when "dmg"
        versions[version][:dmg] = pkg
      when "exe"
        versions[version][:exe] = pkg
      end
    end

    # Find highest version
    highest_version = versions.keys.first
    versions.keys.each do |version|
      if version_less_than?(highest_version, version)
        highest_version = version
      end
    end

    # Choose package type based on platform
    case node[:platform]
    when "debian", "ubuntu", "mint", "pop"
      # Prefer .deb, fall back to AppImage
      if versions[highest_version][:deb]
        return versions[highest_version][:deb]
      elsif versions[highest_version][:appimage]
        return versions[highest_version][:appimage]
      end
    when "darwin", "osx"
      if versions[highest_version][:dmg]
        return versions[highest_version][:dmg]
      end
    when "windows"
      if versions[highest_version][:exe]
        return versions[highest_version][:exe]
      end
    else
      # Other Linux platforms - use AppImage
      if versions[highest_version][:appimage]
        return versions[highest_version][:appimage]
      end
    end

    # If no suitable package found for platform, return first available
    packages.first
  end
end

::MItamae::RecipeContext.include RpiImagerHelper
::MItamae::ResourceContext.include RpiImagerHelper

# Install rpi-imager using latest AppImage from downloads page
case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  home = node[:home]
  user = node[:user]
  cache_dir = "#{home}/.cache/rpi-imager"
  local_bin = node[:user_bin] || "#{home}/.local/bin"

  directory cache_dir do
    owner user
    group node[:group] || user
    mode "755"
  end

  directory local_bin do
    owner user
    group node[:group] || user
    mode "755"
  end

  # Get best available package (prefers .deb if available at same version)
  best_pkg = rpi_imager_best_package_info
  latest_version = best_pkg ? best_pkg[:version] : nil
  pkg_type = best_pkg ? best_pkg[:type] : nil
  installed_version = rpi_imager_installed_version

  MItamae.logger.info "RPi Imager installed version: #{installed_version}"
  MItamae.logger.info "RPi Imager latest version: #{latest_version} (type: #{pkg_type})"

  # Check if .deb is currently installed
  deb_installed = run_command("dpkg -l | grep -i rpi-imager", error: false).success?
  # Check if AppImage is currently installed
  appimage_path = File.join(local_bin, "rpi-imager")
  appimage_installed = File.exist?(appimage_path)

  # Determine installed type
  installed_type = if deb_installed
    "deb"
  elsif appimage_installed
    "AppImage"
  end

  needs_update = if latest_version.nil?
    # If we can't determine latest version, check if any version is installed
    !deb_installed && !appimage_installed
  else
    # Update if:
    # 1. No version installed
    # 2. Installed version is older
    # 3. Installed type doesn't match preferred type (even if same version)
    installed_version.nil? ||
      version_less_than?(installed_version, latest_version) ||
      (installed_version == latest_version && installed_type != pkg_type)
  end

  if needs_update && best_pkg
    download_url = "https://downloads.raspberrypi.com/imager/#{best_pkg[:filename]}"

    case pkg_type
    when "deb"
      download_path = "#{cache_dir}/rpi-imager-#{latest_version}.deb"
      MItamae.logger.info "Downloading RPi Imager .deb to #{download_path}"

      http_request download_path do
        url download_url
        path download_path
        owner user
        notifies :run, "execute[install rpi-imager deb]"
      end

      execute "install rpi-imager deb" do
        action :nothing
        command "apt install -y #{download_path}"
        user "root"
      end

      # Remove AppImage if present (since we're installing .deb)
      execute "remove AppImage when installing deb" do
        command "rm -f #{appimage_path}"
        only_if "test -f #{appimage_path}"
        user user
      end

    when "AppImage"
      download_path = "#{cache_dir}/rpi-imager-#{latest_version}.AppImage"
      MItamae.logger.info "Downloading RPi Imager AppImage to #{download_path}"

      http_request download_path do
        url download_url
        path download_path
        owner user
        notifies :run, "execute[make rpi-imager executable]"
      end

      execute "make rpi-imager executable" do
        action :nothing
        command "chmod +x #{download_path}"
        user user
        notifies :run, "execute[install rpi-imager appimage]"
      end

      execute "install rpi-imager appimage" do
        action :nothing
        command "mv -f #{download_path} #{appimage_path}"
        user user
      end

      # Remove .deb package if present (since we're installing AppImage)
      package "rpi-imager" do
        action :remove
        only_if "dpkg -l | grep -i rpi-imager"
      end
    end
  else
    # Ensure existing AppImage is executable if present
    execute "ensure rpi-imager executable" do
      command "chmod +x #{appimage_path}"
      only_if "test -f #{appimage_path}"
      user user
    end

    # Clean up conflicting installation types
    if pkg_type == "deb" && appimage_installed
      execute "remove AppImage when .deb is preferred" do
        command "rm -f #{appimage_path}"
        user user
      end
    elsif pkg_type == "AppImage" && deb_installed
      package "rpi-imager" do
        action :remove
      end
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
