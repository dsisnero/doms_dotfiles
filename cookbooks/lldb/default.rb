# Install lldb and lldb-dap across platforms.
#
# Both Helix (cookbooks/dotfiles/templates/helix/languages.toml.erb) and
# Neovim (nvim-dap / astronvim_config) invoke `lldb-dap` via PATH, so this
# cookbook ensures a working `lldb-dap` (and `lldb`) is available on PATH.
#
# - macOS (darwin): Prefer the version bundled with Xcode / Command Line
#   Tools (`xcrun lldb-dap`). Xcode only began shipping `lldb-dap` with
#   Xcode 16, so its presence implies a current LLDB; fall back to Homebrew's
#   keg-only `lldb` formula (which ships `lldb-dap`) when Xcode does not
#   provide it. Symlinks are placed into `~/.local/bin`.
# - Linux: install the distribution `lldb` package (provides lldb-dap).
# - Windows: install LLVM via winget and symlink `lldb-dap`/`lldb` into the
#   user bin directory.
#
# Guards use the cross-platform `file_exists?`/`dir_exists?` helpers (and
# Ruby `File.*` predicates) rather than shell `test -e`, which is not
# portable to Windows PowerShell.

module LlDBHelper
  def xcode_has_lldb_dap?
    result = run_command("xcrun -f lldb-dap 2>/dev/null", error: false)
    result.success? && !result.stdout.strip.empty?
  end

  def brew_lldb_installed?
    result = run_command("brew list --versions lldb 2>/dev/null", error: false)
    result.success? && !result.stdout.strip.empty?
  end

  def brew_lldb_bin(binary)
    result = run_command("brew --prefix lldb 2>/dev/null", error: false)
    return nil unless result.success?

    File.join(result.stdout.strip, "bin", binary)
  end

  def xcode_lldb_bin(binary)
    result = run_command("xcrun -f #{binary} 2>/dev/null", error: false)
    return nil unless result.success?

    path = result.stdout.strip
    path.empty? ? nil : path
  end
end

::MItamae::RecipeContext.include LlDBHelper
::MItamae::ResourceContext.include LlDBHelper

user = node[:user]
home = node[:home]
user_bin = node[:user_bin] || File.join(home, ".local", "bin")

directory user_bin do
  owner user
  group node[:group] || user
  mode "755"
end

# Symlink a provider lldb/lldb-dap into the user bin directory so it is
# available on PATH for Helix and Neovim. Providers differ by platform.
define :link_lldb, source: nil do
  binary = params[:name]
  link_path = File.join(user_bin, binary)
  source = params[:source]

  if windows?
    execute "link #{binary} (windows)" do
      command "New-Item -ItemType SymbolicLink -Path '#{link_path}' -Target '#{source}' -Force | Out-Null"
      interpreter "powershell"
      only_if { file_exists?(source) }
      not_if { file_exists?(link_path) }
    end
  else
    execute "link #{binary}" do
      command "ln -sf '#{source}' '#{link_path}'"
      user user
      not_if do
        ::File.exist?(link_path) &&
          begin
            ::File.readlink(link_path) == source
          rescue
            false
          end
      end
    end
  end
end

case node[:platform]
when "darwin", "osx"
  if xcode_has_lldb_dap?
    MItamae.logger.info "Using Xcode / Command Line Tools lldb-dap"
    link_lldb "lldb-dap" do
      source xcode_lldb_bin("lldb-dap")
    end
    link_lldb "lldb" do
      source xcode_lldb_bin("lldb")
    end
  else
    MItamae.logger.info "Xcode lldb-dap unavailable; using Homebrew lldb"
    package "lldb" unless brew_lldb_installed?
    link_lldb "lldb-dap" do
      source brew_lldb_bin("lldb-dap")
    end
    link_lldb "lldb" do
      source brew_lldb_bin("lldb")
    end
  end

when "debian", "ubuntu", "mint", "pop", "redhat", "fedora", "amazon", "arch", "opensuse"
  package "lldb"

when "windows"
  llvm_bin = File.join("C:/Program Files/LLVM", "bin")

  execute "install lldb via winget" do
    command "winget install --id LLVM.LLVM --accept-source-agreements --accept-package-agreements --silent"
    interpreter "powershell"
    not_if { file_exists?(File.join(llvm_bin, "lldb-dap.exe")) }
  end

  %w[lldb-dap lldb].each do |binary|
    link_lldb binary do
      source File.join(llvm_bin, "#{binary}.exe")
    end
  end

else
  MItamae.logger.warn "lldb install not implemented for platform #{node[:platform]}"
end
