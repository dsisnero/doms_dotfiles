include_recipe "dependency.rb"
module RpiImagerHelper
  def rpi_imager_installed_version
    begin
      case node[:platform]
      when "debian", "ubuntu", "mint", "pop"
        # Check dpkg for .deb installation first
        result = run_command("dpkg -l | grep -i '^ii.*rpi-imager'", error: false)
        if result.success?
          MItamae.logger.debug "dpkg output: #{result.stdout}"
          # Extract version column (third column) from dpkg output
          match = result.stdout.match(/rpi-imager\s+(\S+)/i)
          if match
            version_str = match[1]
            MItamae.logger.debug "dpkg version column: #{version_str}"
            # Strip epoch if present (e.g., "1:1.9.6" -> "1.9.6")
            version_str = version_str.sub(/^\d+:/, "")
            version_match = version_str.match(/(\d+(?:\.\d+)+)/)
            if version_match
              MItamae.logger.debug "dpkg extracted version: #{version_match[1]}"
              return version_match[1]
            end
          end
        end
        # Check if AppImage exists and get its version
        appimage_path = File.join(node[:user_bin], "rpi-imager")
        if File.exist?(appimage_path)
          # Try to get version from AppImage
          result = run_command("#{appimage_path} --version 2>/dev/null", error: false)
          if result.success?
            MItamae.logger.debug "AppImage version output: #{result.stdout}"
            # Extract version from output, e.g., "Raspberry Pi Imager v1.9.6"
            match = result.stdout.match(/v(\d+\.\d+\.\d+)/)
            if match
              MItamae.logger.debug "AppImage extracted version: #{match[1]}"
              return match[1]
            end
          end
        end
        # Also check snap version
        result = run_command("snap list rpi-imager 2>/dev/null | grep rpi-imager", error: false)
        if result.success?
          MItamae.logger.debug "snap output: #{result.stdout}"
          # Extract second column (version) from snap output
          match = result.stdout.match(/rpi-imager\s+(\S+)/i)
          if match
            version_str = match[1]
            MItamae.logger.debug "snap version column: #{version_str}"
            # Strip epoch if present
            version_str = version_str.sub(/^\d+:/, "")
            version_match = version_str.match(/(\d+(?:\.\d+)+)/)
            if version_match
              MItamae.logger.debug "snap extracted version: #{version_match[1]}"
              return version_match[1]
            end
          end
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

  appimage_path = File.join(local_bin, "rpi-imager")
  appimage_installed = File.exist?(appimage_path)
  deb_installed = run_command("dpkg -l | grep -i '^ii.*rpi-imager'", error: false).success?

  installed_version = rpi_imager_installed_version
  MItamae.logger.info "RPi Imager installed version: #{installed_version}"

  # Determine installed type
  installed_type = if deb_installed
    "deb"
  elsif appimage_installed
    "AppImage"
  end

  # Skip network check if already installed — avoids hitting raspberrypi.com every run
  if installed_version.nil?
    # Not installed: fetch latest and install
    best_pkg = rpi_imager_best_package_info
    latest_version = best_pkg ? best_pkg[:version] : nil
    pkg_type = best_pkg ? best_pkg[:type] : nil
    needs_download = latest_version && best_pkg
    MItamae.logger.info "RPi Imager latest version: #{latest_version} (type: #{pkg_type})"
  else
    MItamae.logger.info "RPi Imager already installed, skipping latest version check"
    latest_version = nil
    needs_download = false
  end

  if needs_download && best_pkg
    download_url = "https://downloads.raspberrypi.com/imager/#{best_pkg[:filename]}"

    case pkg_type
    when "deb"
      download_path = "#{cache_dir}/rpi-imager-#{latest_version}.deb"
      MItamae.logger.info "Downloading and installing RPi Imager .deb"

      execute "download and install rpi-imager deb" do
        command <<-EOS
          set -e
          curl -s -L -o "#{download_path}" "#{download_url}"
          apt install -y "#{download_path}"
        EOS
        not_if "dpkg -l | grep -i '^ii.*rpi-imager' | grep -q #{latest_version}"
        user "root"
      end

      execute "remove AppImage when installing deb" do
        command "rm -f #{appimage_path}"
        only_if "test -f #{appimage_path}"
        user user
      end

    when "AppImage"
      download_path = "#{cache_dir}/rpi-imager-#{latest_version}.AppImage"
      MItamae.logger.info "Downloading and installing RPi Imager AppImage to #{appimage_path}"

      execute "download and install rpi-imager appimage" do
        command <<-EOS
          set -e
          curl -s -L -o "#{download_path}" "#{download_url}"
          chmod +x "#{download_path}"
          mv -f "#{download_path}" "#{appimage_path}"
        EOS
        not_if "test -f #{appimage_path} && #{appimage_path} --version 2>/dev/null | grep -q v#{latest_version}"
        user user
      end

      execute "remove old deb rpi-imager" do
        command "apt remove -y rpi-imager-amd64 rpi-imager 2>/dev/null || true"
        only_if "dpkg -l | grep -i '^ii.*rpi-imager'"
        user "root"
      end
    end
  end

  # One-time cleanup: remove leftover snap if it exists
  execute "remove old snap rpi-imager" do
    command "snap remove rpi-imager --purge 2>/dev/null || true"
    only_if "snap list rpi-imager 2>/dev/null"
    user "root"
  end

  # Ensure AppImage is executable (only when it's not already)
  execute "ensure rpi-imager executable" do
    command "chmod +x #{appimage_path}"
    only_if "test -f #{appimage_path} && ! test -x #{appimage_path}"
    user user
  end

when "osx", "darwin"
  package "raspberry-pi-imager"

when "windows"
  # Windows installation would require downloading the installer
  # Not implemented in this cookbook
  log "Raspberry Pi Imager for Windows not implemented in this cookbook"
end
