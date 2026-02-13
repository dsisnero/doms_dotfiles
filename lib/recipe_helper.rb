class Specinfra::Command::Pop < Specinfra::Command::Ubuntu
end

#
# ----- RECIPE HELPERS --------------------------------
MItamae::RecipeContext.class_eval do
  def include_cookbook(name)
    include_recipe File.join(root_dir, "cookbooks", name, "default")
  end

  def root_dir
    File.expand_path("../..", __FILE__)
  end

  def include_role(name)
    include_recipe File.join(root_dir, "roles", name, "default")
  end

  def include_definition(name)
    include_recipe File.join(root_dir, "definitions", "#{name}.rb")
  end
end

# ─── PLATFORM HELPERS ───────────────────────────────────────────────
#
module PlatformHelpers
  def windows?
    node[:family] == "windows"
  end

  def wsl?
    node[:cygwin]
  end

  def platform_family
    node[:family]
  end

  def version_less_than?(v1, v2)
    return false if v1.nil? || v2.nil?

    # Normalize versions: strip any leading non-digit characters
    v1_norm = v1.to_s.strip.gsub(/^[^0-9]+/, "")
    v2_norm = v2.to_s.strip.gsub(/^[^0-9]+/, "")

    # Manual version comparison
    v1_parts = v1_norm.split(".").map(&:to_i)
    v2_parts = v2_norm.split(".").map(&:to_i)

    # Compare each part
    max_length = [v1_parts.length, v2_parts.length].max
    max_length.times do |i|
      p1 = v1_parts[i] || 0
      p2 = v2_parts[i] || 0
      return true if p1 < p2
      return false if p1 > p2
    end

    # All parts equal
    false
  end
end

#
# ─── NODE INITIALIZER ───────────────────────────────────────────────
#
module NodeInitializer
  def detect_role
    # Environment variable takes precedence
    if ENV["ROLE"] && !ENV["ROLE"].empty?
      return ENV["ROLE"].downcase
    end

    # Hostname-based detection
    hostname = run_command("hostname -s", error: false)
    if hostname.success?
      name = hostname.stdout.strip.downcase
      # Mapping prefixes
      if name.start_with?("pi-dev")
        "development"
      elsif name.start_with?("pi-media")
        "media"
      elsif name.start_with?("pi-minimal")
        "minimal"
      elsif name.start_with?("pi-ha")
        "home-assistant"
      end
    end
  end

  def set_hostname
    if ENV["HOSTNAME"] && !ENV["HOSTNAME"].empty?
      hostname = ENV["HOSTNAME"].strip
      MItamae.logger.info "Setting hostname to #{hostname}"

      case node[:platform]
      when "debian", "ubuntu", "mint", "pop", "redhat", "fedora", "arch", "opensuse", "amazon"
        # Check current hostname
        current = run_command("hostname -s", error: false)
        if current.success? && current.stdout.strip == hostname
          MItamae.logger.info "Hostname already set to #{hostname}"
          return
        end

        execute "hostnamectl set-hostname #{hostname}"
        file "/etc/hostname" do
          content "#{hostname}\n"
          owner "root"
          group "root"
          mode "644"
        end
        execute "sed -i 's/^127\\.0\\.1\\.1.*/127.0.1.1\\t#{hostname}/' /etc/hosts" do
          only_if "grep -q '^127\\.0\\.1\\.1' /etc/hosts"
        end
      when "darwin"
        # Check current hostname
        current = run_command("scutil --get HostName", error: false)
        if current.success? && current.stdout.strip == hostname
          MItamae.logger.info "Hostname already set to #{hostname}"
          return
        end

        execute "scutil --set HostName #{hostname}"
        execute "scutil --set ComputerName #{hostname}"
        execute "scutil --set LocalHostName #{hostname}"
      when "windows"
        MItamae.logger.warn "Hostname setting not implemented for Windows"
      else
        MItamae.logger.warn "Hostname setting not implemented for platform #{node[:platform]}"
      end
    end
  end

  def init_node
    user = ENV["SUDO_USER"] || ENV["USER"]
    home = if windows?
      ENV["HOME"] || ENV["USERPROFILE"].tr("\\", "/") # Unix-style path
    else
      ENV["HOME"]
    end

    group = case node[:platform]
    when "darwin"
      "staff"
    when "windows"
      user
    else
      result = run_command("id -gn #{user}", error: false)
      if result.exit_status == 0
        result.stdout.strip
      else
        user
      end
    end

    # Unified XDG_CONFIG_HOME handling across all platforms
    xdg_home = home
    user_bin = File.join(home, ".local", "bin")
    repos = "#{home}/repos"
    config_home = ENV.fetch("XDG_CONFIG_HOME", File.join(xdg_home, ".config"))
    data_home = ENV.fetch("XDG_DATA_HOME", File.join(xdg_home, ".local", "share"))
    cache_home = ENV.fetch("XDG_CACHE_HOME", File.join(xdg_home, ".cache"))
    state_home = ENV.fetch("XDG_STATE_HOME", File.join(xdg_home, ".local", "state"))
    my_repos = "#{repos}/github.com/dsisnero"
    doms_dotfiles = "#{my_repos}/doms_dotfiles"

    role = detect_role
    node.reverse_merge!(
      user: user,
      home: home,
      group: group,
      config_home: config_home,
      data_home: data_home,
      cache_home: cache_home,
      state_home: state_home,
      user_bin: user_bin,
      repos: repos,
      my_repos: my_repos,
      doms_dotfiles: doms_dotfiles,
      zshrc_config: File.join(doms_dotfiles, "config", ".zshrc"),
      role: role
    )
    if windows?
      include_recipe "windows_node"
    end
    MItamae.logger.info "Node initialized for #{user} (#{node[:family]})"
  end
end

#
# ─── USER CONTEXT HELPERS ───────────────────────────────────────────
#
module UserContextHelpers
  def sudo(user)
    return "" if windows? || platform_family == "macos"
    "sudo -u #{user} -i "
  end

  def run_as(user, cmd)
    if windows?
      "powershell -Command \"Start-Process -FilePath 'cmd' -ArgumentList '/c #{cmd.gsub('"', '\"')}' -Verb RunAs\""
    elsif platform_family == "macos"
      cmd
    else
      "su - #{user} -c \"cd ${PWD} && SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock #{cmd}\""
    end
  end
end

#
# ─── GITHUB API HELPER (shell-based) ────────────────────────────────
#
module GitHubHelpers
  def github_versions(repo)
    max_retries = 3
    retry_count = 0
    while retry_count < max_retries
      cmd = "curl -s https://api.github.com/repos/#{repo}/tags?per_page=100 | jq -r '.[].name'"
      result = run_command(cmd, error: false)
      if result.exit_status == 0
        return result.stdout.split("\n")
      end
      retry_count += 1
      sleep 2 if retry_count < max_retries
    end
    []
  end

  def normalize_version(version_string)
    return nil if version_string.nil?
    # Strip any leading non-digit characters
    version_string.strip.gsub(/^[^0-9]+/, "")
  end

  def github_latest_tag(repo)
    max_retries = 3
    retry_count = 0
    while retry_count < max_retries
      cmd = "curl -s https://api.github.com/repos/#{repo}/releases/latest | jq -r '.tag_name'"
      result = run_command(cmd, error: false)
      if result.exit_status == 0
        return result.stdout.strip
      end
      retry_count += 1
      sleep 2 if retry_count < max_retries
    end
    nil
  end

  def github_latest_version(repo)
    tag = github_latest_tag(repo)
    tag ? normalize_version(tag) : nil
  end

  # Helper to compute target string like install_opencode.1.sh
  def compute_target_info(node)
    # Determine OS
    os = case node[:platform]
    when "debian", "ubuntu", "mint", "fedora", "redhat", "amazon", "arch", "opensuse"
      "linux"
    when "darwin", "osx"
      "darwin"
    when "windows"
      "windows"
    else
      "linux" # default
    end

    # Determine architecture
    arch = node[:kernel][:machine]
    case arch
    when "aarch64"
      arch = "arm64"
    when "x86_64"
      arch = "x64"
    end

    # Handle macOS Rosetta detection
    if os == "darwin" && arch == "x64"
      result = run_command("sysctl -n sysctl.proc_translated 2>/dev/null || echo 0", error: false)
      if result.stdout.strip == "1"
        arch = "arm64"
      end
    end

    # Check for musl (Linux only)
    is_musl = false
    if os == "linux"
      # Check /etc/alpine-release
      if File.exist?("/etc/alpine-release")
        is_musl = true
      end

      # Check ldd
      result = run_command("ldd --version 2>&1 || echo ''", error: false)
      if result.stdout.downcase.include?("musl")
        is_musl = true
      end
    end

    # Check for baseline CPU (no AVX2)
    needs_baseline = false
    if arch == "x64"
      if os == "linux"
        result = run_command("grep -qi avx2 /proc/cpuinfo 2>/dev/null || echo ''", error: false)
        needs_baseline = !result.success?
      elsif os == "darwin"
        result = run_command("sysctl -n hw.optional.avx2_0 2>/dev/null || echo 0", error: false)
        needs_baseline = result.stdout.strip != "1"
      end
    end

    # Build target string
    target = "#{os}-#{arch}"
    if needs_baseline
      target = "#{target}-baseline"
    end
    if is_musl
      target = "#{target}-musl"
    end

    target
  end
end

#
# ─── CALIBRE HELPERS ───────────────────────────────────────────────────────
#
module CalibreHelpers
  def dedrm_installed_version
    # Try to get DeDRM version from calibre-debug command
    cmd = 'calibre-debug -r "DeDRM" 2>&1 | head -1'
    result = run_command(cmd, error: false)

    if result.success?
      # Extract version from output like "DeDRM v10.0.9 - DRM removal plugin by noDRM"
      match = result.stdout.match(/DeDRM\s+v?([\d.]+)/i)
      return match[1] if match
    end

    nil
  end

  def dedrm_needs_update?(installed_version, latest_version)
    return true if installed_version.nil? || latest_version.nil?
    version_less_than?(installed_version, latest_version)
  end
end

#
# ─── BACKUP HELPERS ───────────────────────────────────────────────────
#
module BackupHelpers
  # Generate a bash script for incremental backup of a file
  # Creates backups with pattern: file.backup, file.backup.2, file.backup.3, etc.
  # IMPORTANT: This only works on Unix-like systems (Linux, macOS)
  # For Windows, implement PowerShell-based backup logic in the cookbook
  #
  # @param file_path [String] Path to the file to backup
  # @param backup_suffix [String] Suffix for backup files (default: ".backup")
  # @return [String] Bash script that performs incremental backup
  def incremental_backup_script(file_path, backup_suffix = ".backup")
    # Escape regex special characters in file path and suffix for bash regex
    # Bash uses extended regex (ERE) syntax
    escaped_path = file_path.gsub(/[.*+?^${}()|\[\]\\]/, '\\\\\\0')
    escaped_suffix = backup_suffix.gsub(/[.*+?^${}()|\[\]\\]/, '\\\\\\0')

    <<~EOH
      if [ -f "#{file_path}" ]; then
        # Find highest backup number
        max_num=0
        for bak in "#{file_path}#{backup_suffix}"*; do
          if [[ $bak =~ #{escaped_path}#{escaped_suffix}\\.([0-9]+)$ ]]; then
            num=${BASH_REMATCH[1]}
            [ $num -gt $max_num ] && max_num=$num
          elif [[ $bak == "#{file_path}#{backup_suffix}" ]]; then
            max_num=1  # .backup exists, start from .backup.2
          fi
        done

        # Create next backup
        if [ $max_num -eq 0 ]; then
          cp -f "#{file_path}" "#{file_path}#{backup_suffix}"
        else
          next_num=$((max_num + 1))
          cp -f "#{file_path}" "#{file_path}#{backup_suffix}.${next_num}"
        fi
      fi
    EOH
  end
end

#
# ─── DEFINES ───────────────────────────────────────────────────────

include_definition "dotfile"
include_definition "mydir"
include_definition "get_repo"
include_definition "launch_env"

#
# ─── INCLUDE HELPERS ───────────────────────────────────────────────
#
::MItamae::RecipeContext.include PlatformHelpers
::MItamae::RecipeContext.include NodeInitializer
::MItamae::RecipeContext.include UserContextHelpers
::MItamae::RecipeContext.include GitHubHelpers
::MItamae::RecipeContext.include CalibreHelpers
::MItamae::RecipeContext.include BackupHelpers

::MItamae::ResourceContext.include PlatformHelpers
::MItamae::ResourceContext.include UserContextHelpers
::MItamae::ResourceContext.include CalibreHelpers
::MItamae::ResourceContext.include BackupHelpers
::MItamae::RecipeContext.include GitHubHelpers

# go_get definition moved to cookbooks/go/default.rb
init_node
set_hostname
MItamae.logger.info "Node Info:\n#{node.inspect}"
MItamae.logger.info %(Mitamae Versions{ github_versions("itamae-kitchen/mitamae") })