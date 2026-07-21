include_definition "mas"

# 1. Headless Installation of Standalone Command Line Tools
execute 'install_xcode_clt_headless' do
  command <<~SHELL
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F ".*: " '{print $2}' | sed -e 's/^ *//' -e 's/ *$//')
    if [ -n "$PROD" ]; then
      softwareupdate -i "$PROD" --verbose
    fi
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  SHELL
  not_if 'xcode-select -p'
end

# 2. Complete Xcode Installation (via App Store CLI tool 'mas')
# Note: Ensure you are logged into the App Store on the host machine first.
mas 'xcode' do
  id '497799835'
  not_if 'test -d /Applications/Xcode.app'
end

# 3. Complete First-Launch Setup and Automatically Accept Licenses
execute 'accept_xcode_licenses_and_components' do
  command <<~SHELL
    # Ensure the system points to the full Xcode app directory path
    xcode-select -s /Applications/Xcode.app/Contents/Developer

    # Accept the Apple developer license agreements silently
    xcodebuild -license accept

    # Download and activate core platform components (iOS/macOS SDK runtimes)
    xcodebuild -runFirstLaunch
  SHELL
  # Only trigger if the active toolchain path points to the standalone CLT directory instead of the full app
  only_if 'xcode-select -p | grep -q "CommandLineTools"'
end

