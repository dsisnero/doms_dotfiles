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
    include_recipe File.join(root_dir, "definitions", name)
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
end

#
# ─── NODE INITIALIZER ───────────────────────────────────────────────
#
module NodeInitializer
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

    xdg_home = home
    user_bin = File.join(home, ".local", "bin")

    repos = "#{home}/repos"

    # Unified XDG_CONFIG_HOME handling across all platforms
    config_home = ENV.fetch("XDG_CONFIG_HOME", File.join(xdg_home, ".config"))
    data_home = ENV.fetch("XDG_DATA_HOME", File.join(xdg_home, ".local", "share"))
    cache_home = ENV.fetch("XDG_CACHE_HOME", File.join(xdg_home, ".cache"))
    my_repos = "#{repos}/github.com/dsisnero"
    doms_dotfiles = "#{my_repos}/doms_dotfiles"

    node.reverse_merge!(
      user: user,
      home: home,
      group: group,
      config_home: config_home,
      data_home: data_home,
      cache_home: cache_home,
      user_bin: user_bin,
      repos: repos,
      my_repos: my_repos,
      doms_dotfiles: doms_dotfiles,
      zshrc_config: File.join(doms_dotfiles, "config", ".zshrc")
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

  def github_latest_version(repo)
    max_retries = 3
    retry_count = 0
    while retry_count < max_retries
      cmd = "curl -s https://api.github.com/repos/#{repo}/releases/latest | jq -r '.tag_name'"
      result = run_command(cmd, error: false)
      if result.exit_status == 0
        return result.stdout.strip.gsub(/^v/, "")
      end
      retry_count += 1
      sleep 2 if retry_count < max_retries
    end
    nil
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

::MItamae::ResourceContext.include PlatformHelpers
::MItamae::ResourceContext.include UserContextHelpers
::MItamae::RecipeContext.include GitHubHelpers

# go_get definition moved to cookbooks/go/default.rb
init_node
MItamae.logger.info "Node Info:\n#{node.inspect}"
MItamae.logger.info %(Mitamae Versions{ github_versions("itamae-kitchen/mitamae") })
