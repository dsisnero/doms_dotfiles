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

  def version_less_than?(v1, v2)
    return false if v1.nil? || v2.nil?

    # Normalize versions: strip leading 'v' and whitespace
    v1_norm = v1.to_s.strip.gsub(/^v/, "")
    v2_norm = v2.to_s.strip.gsub(/^v/, "")

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
    else
      "user"
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
    cmd = "curl -s https://api.github.com/repos/#{repo}/tags?per_page=100 | jq -r '.[].name'"
    result = run_command(cmd, error: false)
    (result.exit_status == 0) ? result.stdout.split("\n") : []
  end

  def github_latest_version(repo)
    cmd = "curl -s https://api.github.com/repos/#{repo}/releases/latest | jq -r '.tag_name'"
    result = run_command(cmd, error: false)
    (result.exit_status == 0) ? result.stdout.strip.gsub(/^v/, "") : nil
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
