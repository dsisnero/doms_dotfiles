case node[:platform]
when "osx", "darwin"
  package "calibre"

  calibre_customize = "/Applications/calibre.app/Contents/MacOS/calibre-customize"

  # Download DeDRM plugin
  dedrm_url = "https://github.com/noDRM/DeDRM_tools/releases/download/v10.0.3/DeDRM_tools_10.0.3.zip"
  dedrm_zip = "/tmp/DeDRM_tools_10.0.3.zip"
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

  # Install DeDRM plugin
  execute "install DeDRM plugin" do
    command "#{calibre_customize} --add-plugin #{dedrm_plugin_zip}"
    user node[:user]
    only_if "test -f #{calibre_customize} && test -f #{dedrm_plugin_zip}"
    not_if "#{calibre_customize} --list-plugins 2>/dev/null | grep -q 'DeDRM'"
  end

  # Enable KFX Input plugin (included in Calibre distribution)
  execute "enable KFX Input plugin" do
    command "#{calibre_customize} --add-plugin KFX_Input"
    user node[:user]
    only_if "test -f #{calibre_customize}"
    not_if "#{calibre_customize} --list-plugins 2>/dev/null | grep -q 'KFX Input'"
  end

when "debian", "ubuntu", "mint", "pop"
  package "calibre"

  # Download DeDRM plugin
  dedrm_url = "https://github.com/noDRM/DeDRM_tools/releases/download/v10.0.3/DeDRM_tools_10.0.3.zip"
  dedrm_zip = "/tmp/DeDRM_tools_10.0.3.zip"
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

  # Install DeDRM plugin
  execute "install DeDRM plugin" do
    command "calibre-customize --add-plugin #{dedrm_plugin_zip}"
    user node[:user]
    only_if "which calibre-customize && test -f #{dedrm_plugin_zip}"
    not_if "calibre-customize --list-plugins 2>/dev/null | grep -q 'DeDRM'"
  end

  # Enable KFX Input plugin (included in Calibre distribution)
  execute "enable KFX Input plugin" do
    command "calibre-customize --add-plugin KFX_Input"
    user node[:user]
    only_if "which calibre-customize"
    not_if "calibre-customize --list-plugins 2>/dev/null | grep -q 'KFX Input'"
  end
end
