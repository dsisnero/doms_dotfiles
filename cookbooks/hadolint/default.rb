include_recipe "dependency.rb"

# Determine platform-specific asset name
case node[:platform]
when "debian", "ubuntu", "mint", "fedora", "redhat", "amazon", "arch", "opensuse"
  # Linux platforms
  arch = (node[:kernel] && node[:kernel][:machine]) ? node[:kernel][:machine] : "x86_64"
  asset_name = "hadolint-Linux-#{arch}"

  github_binary "hadolint" do
    repo "hadolint/hadolint"
    version "v2.12.0"
    asset_pattern asset_name
    binary_name "hadolint"
    install_path "/usr/local/bin/hadolint"
    user "root"
    mode "0755"
    extract false  # Raw binary, not an archive
    strip_components 0
  end
when "osx", "darwin"
  # macOS - hadolint only provides x86_64 binary, would need Rosetta
  # Skip for now since we're on ARM64
end
