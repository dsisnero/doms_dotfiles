dedrm_repo = "noDRM/DeDRM_tools"
dedrm_tag = github_latest_tag(dedrm_repo)
dedrm_version = github_latest_version(dedrm_repo)

if dedrm_tag.nil? || dedrm_version.nil?
  MItamae.logger.warn "Failed to fetch latest DeDRM version from GitHub, using fallback v10.0.3"
  dedrm_tag = "v10.0.3"
  dedrm_version = "10.0.3"
else
  MItamae.logger.info "Latest DeDRM version: #{dedrm_tag}"
end

# Check installed version
installed_version = dedrm_installed_version
MItamae.logger.info "Installed DeDRM version: #{installed_version || "not installed"}"

# Determine if update is needed
needs_update = installed_version.nil? || version_less_than?(installed_version, dedrm_version)

if needs_update
  MItamae.logger.info "DeDRM update required: #{installed_version || "not installed"} -> #{dedrm_version}"
else
  MItamae.logger.info "DeDRM is up to date: #{installed_version}"
end

case node[:platform]
when "osx", "darwin"
  package "calibre"

  calibre_customize = "/Applications/calibre.app/Contents/MacOS/calibre-customize"

  # Download DeDRM plugin
  dedrm_url = "https://github.com/#{dedrm_repo}/releases/download/#{dedrm_tag}/DeDRM_tools_#{dedrm_version}.zip"
  dedrm_zip = "/tmp/DeDRM_tools_#{dedrm_version}.zip"
  dedrm_plugin_zip = "/tmp/DeDRM_plugin.zip"

  execute "download DeDRM tools" do
    command <<~EOCMD
      for i in {1..5}; do
        curl -fL -o #{dedrm_zip} #{dedrm_url} && break || sleep 2
      done
    EOCMD
    user node[:user]
    not_if "test -f #{dedrm_zip}"
  end

  # Extract DeDRM_plugin.zip from the downloaded archive
  execute "extract DeDRM plugin" do
    command "unzip -j -o #{dedrm_zip} 'DeDRM_plugin.zip' -d /tmp"
    user node[:user]
    only_if "test -f #{dedrm_zip}"
    not_if "test -f #{dedrm_plugin_zip}"
  end

  # Install DeDRM plugin if update is needed
  execute "install DeDRM plugin" do
    command "#{calibre_customize} --add-plugin #{dedrm_plugin_zip}"
    user node[:user]
    only_if "test -f #{calibre_customize} && test -f #{dedrm_plugin_zip}"
    not_if do
      # Skip if already installed and up to date
      if needs_update
        false  # We need to install/update
      else
        # Check if plugin is actually installed (belt-and-suspenders)
        result = run_command("#{calibre_customize} --list-plugins 2>/dev/null | grep -q 'DeDRM'", error: false)
        result.success?
      end
    end
  end

  # Enable KFX Input plugin (included in Calibre distribution)
  execute "enable KFX Input plugin" do
    command "#{calibre_customize} --add-plugin KFX_Input"
    user node[:user]
    only_if "test -f #{calibre_customize}"
    not_if "#{calibre_customize} --list-plugins 2>/dev/null | grep -q 'KFX Input'"
  end

when "debian", "ubuntu", "mint", "pop"
  # Remove apt package if present (interferes with binary install)
  execute "remove apt calibre" do
    command "apt-get remove -y calibre calibre-bin 2>/dev/null; apt-get autoremove -y 2>/dev/null; true"
    only_if "dpkg -l calibre 2>/dev/null | grep -q '^ii'"
  end

  calibre_installed = calibre_installed_version
  calibre_latest = calibre_latest_version

  if calibre_latest.nil?
    MItamae.logger.warn "Failed to fetch latest Calibre version, skipping binary install"
  else
    MItamae.logger.info "Calibre: installed=#{calibre_installed || 'none'}, latest=#{calibre_latest}"
  end

  execute "install calibre" do
    command "wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin"
    user "root"
    only_if { calibre_latest && (calibre_installed.nil? || version_less_than?(calibre_installed, calibre_latest)) }
  end

  # Download DeDRM plugin
  dedrm_url = "https://github.com/#{dedrm_repo}/releases/download/#{dedrm_tag}/DeDRM_tools_#{dedrm_version}.zip"
  dedrm_zip = "/tmp/DeDRM_tools_#{dedrm_version}.zip"
  dedrm_plugin_zip = "/tmp/DeDRM_plugin.zip"

  execute "download DeDRM tools" do
    command <<~EOCMD
      for i in {1..5}; do
        curl -fL -o #{dedrm_zip} #{dedrm_url} && break || sleep 2
      done
    EOCMD
    user node[:user]
    not_if "test -f #{dedrm_zip}"
  end

  # Extract DeDRM_plugin.zip from the downloaded archive
  execute "extract DeDRM plugin" do
    command "unzip -j -o #{dedrm_zip} 'DeDRM_plugin.zip' -d /tmp"
    user node[:user]
    only_if "test -f #{dedrm_zip}"
    not_if "test -f #{dedrm_plugin_zip}"
  end

  # Install DeDRM plugin if update is needed
  execute "install DeDRM plugin" do
    command "calibre-customize --add-plugin #{dedrm_plugin_zip}"
    user node[:user]
    only_if "which calibre-customize && test -f #{dedrm_plugin_zip}"
    not_if do
      # Skip if already installed and up to date
      if needs_update
        false  # We need to install/update
      else
        # Check if plugin is actually installed (belt-and-suspenders)
        result = run_command("calibre-customize --list-plugins 2>/dev/null | grep -q 'DeDRM'", error: false)
        result.success?
      end
    end
  end

  # Enable KFX Input plugin (included in Calibre distribution)
  execute "enable KFX Input plugin" do
    command "calibre-customize --add-plugin KFX_Input"
    user node[:user]
    only_if "which calibre-customize"
    not_if "calibre-customize --list-plugins 2>/dev/null | grep -q 'KFX Input'"
  end
end
