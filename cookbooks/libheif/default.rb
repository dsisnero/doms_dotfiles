include_recipe "dependency.rb"

module LibheifHelper
  def libheif_installed_version
    begin
      result = run_command("pkg-config --modversion libheif 2>/dev/null", error: false)
      if result.success?
        version = result.stdout.strip
        return version unless version.empty?
      end
    rescue => e
      MItamae.logger.warn "Failed to get installed libheif version: #{e.message}"
    end
    nil
  end

  def libheif_needs_update?
    installed = libheif_installed_version
    return true if installed.nil?
    version_less_than?(installed, "1.21")
  end
end

::MItamae::RecipeContext.include LibheifHelper
::MItamae::ResourceContext.include LibheifHelper

case node[:platform]

when "debian", "ubuntu", "mint", "pop"
  home = node[:home]
  user = node[:user]
  cache_dir = "#{home}/.cache/libheif"

  directory cache_dir do
    owner user
    group node[:group] || user
    mode "755"
  end

  installed_version = libheif_installed_version
  MItamae.logger.info "libheif installed version: #{installed_version || 'not installed'}"

  if libheif_needs_update?
    version = github_latest_version("strukturag/libheif")
    MItamae.logger.info "libheif latest version: #{version}"

    url = "https://github.com/strukturag/libheif/archive/refs/tags/v#{version}.tar.gz"
    build_dir = "#{cache_dir}/libheif-#{version}"

    execute "download and extract libheif source" do
      command <<-EOS
        set -e
        curl -s -L -o "#{cache_dir}/libheif-v#{version}.tar.gz" "#{url}"
        tar xzf "#{cache_dir}/libheif-v#{version}.tar.gz" -C "#{cache_dir}"
      EOS
      not_if { File.directory?(build_dir) }
      user user
    end

    execute "build and install libheif" do
      command <<-EOS
        set -e
        cd "#{build_dir}"
        mkdir -p build
        cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
        make -j$(nproc)
        make install
        ldconfig
      EOS
      not_if "pkg-config --modversion libheif | grep -q #{version}"
    end
  else
    MItamae.logger.info "libheif #{installed_version} satisfies minimum version 1.21, skipping build"
  end

when "osx", "darwin"
  package "libheif"

when "windows"
  log "libheif for Windows not implemented in this cookbook"
end
