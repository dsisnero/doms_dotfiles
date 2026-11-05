module OllamaHelper
  def ollama_installed_version
    case node[:platform]
    when "debian", "ubuntu", "mint", "pop"
      binary = "#{node[:home]}/.local/bin/ollama"
      if File.exist?(binary)
        result = run_command("#{binary} --version", error: false)
        result.success? ? result.stdout.strip : nil
      end
    when "darwin"
      plist = "/Applications/Ollama.app/Contents/Info.plist"
      if File.exist?(plist)
        result = run_command("defaults read '#{plist}' CFBundleShortVersionString 2>/dev/null", error: false)
        result.success? ? result.stdout.strip : nil
      end
    end
  end
end

::MItamae::RecipeContext.include OllamaHelper

::MItamae::ResourceContext.include OllamaHelper

include_cookbook "mise"
home = node[:home]
log_dir = "#{home}/.local/state/ollama"

OUTPUT_LOG = File.join(log_dir, "ollama.log")
ERROR_LOG = File.join(log_dir, "ollama_error.log")

mydir log_dir

case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  user_var = node["user"]
  url = "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tar.zst"
  download_path = "/tmp/ollama-linux-amd64.tar.zst"
  home = node["home"]
  local = "#{home}/.local"
  latest_version = github_latest_version("ollama/ollama")
  installed_version = ollama_installed_version
  MItamae.logger.info "Ollama installed version: #{installed_version}"
  MItamae.logger.info "Latest version: #{latest_version}"

  needs_update = if latest_version.nil?
    !run_command("#{sudo(user_var)} which ollama", error: false).success?
  else
    installed_version.nil? || version_less_than?(installed_version, latest_version)
  end

  package "aria2"

  execute "download ollama" do
    command "aria2c --allow-overwrite=true #{url} -d /tmp/ -o ollama-linux-amd64.tar.zst"
    user user_var
    notifies :run, "execute[unzip ollama]", :immediately
    only_if { needs_update }
  end

  execute "unzip ollama" do
    command <<~EOCMD
      tar --zstd -C #{local} -xf #{download_path}
    EOCMD
    user user_var
    action :nothing
  end

when "darwin"
  # ---------------------------------------------------------------------------
  # Ollama.app is the single owner of the server.
  #
  # The app is started at login by launchd (com.ollama.ollama -> Squirrel) and
  # spawns `Contents/Resources/ollama serve` itself, binding port 11434.
  #
  # DO NOT install a second `ollama serve` LaunchAgent (the old
  # com.ollama.serve). Two servers cannot share port 11434: the extra agent
  # fails its bind, KeepAlive restarts it forever, and `launchctl list` shows it
  # with exit status 1. Meanwhile the app's server keeps running with whatever
  # environment *it* was started with. That divergence is exactly what made
  # `ollama list` report `{"models":[]}` while 40 GB of blobs sat on the SSD.
  #
  # The app also self-updates (Squirrel "ShipIt" updater plus the tray "update
  # available" prompt), so keeping the app in the loop is what keeps Ollama on
  # the newest version. Disabling it to run a hand-rolled agent freezes you on
  # whatever binary happens to be on disk and adds a plist to maintain.
  #
  # Model storage therefore has to be arranged for a launchd-started process,
  # which means two independent mechanisms:
  #   1. OLLAMA_MODELS in the launchd *session* environment (not a shell
  #      profile: the app never reads your ~/.zshrc).
  #   2. A ~/.ollama/models -> SSD symlink, because (1) is applied by a
  #      RunAtLoad LaunchAgent and Ollama is also a RunAtLoad LaunchAgent, so
  #      after a reboot either can win the race. The symlink makes the SSD the
  #      model path even when the env var loses.
  # ---------------------------------------------------------------------------
  OLLAMA_URL = "https://github.com/ollama/ollama/releases/latest/download/Ollama.dmg"
  DMG_PATH = "/tmp/Ollama.dmg"
  VOLUME = "/Volumes/Ollama"
  APP_NAME = "Ollama.app"
  DEST_APP = "/Applications/#{APP_NAME}"
  PLIST_PATH = "#{DEST_APP}/Contents/Info.plist"
  SYMLINK_PATH = "/usr/local/bin/ollama"
  MODEL_VOLUME = "/Volumes/extreme_ssd"
  MODEL_PATH = "#{MODEL_VOLUME}/ollama_models"
  DEFAULT_MODELS = "#{home}/.ollama/models"
  APP_LABEL = "com.ollama.ollama"
  LEGACY_LABEL = "com.ollama.serve"
  LEGACY_AGENT = "#{home}/Library/LaunchAgents/#{LEGACY_LABEL}.plist"
  # The CLI lives in Resources/, not MacOS/ (that is the GUI binary).
  CLI_BINARY = "#{DEST_APP}/Contents/Resources/ollama"

  latest_version = github_latest_version("ollama/ollama")

  installed_version = ollama_installed_version
  MItamae.logger.info "Ollama installed version: #{installed_version}"
  MItamae.logger.info "Latest version #{latest_version}"
  needs_update = if latest_version.nil?
    !File.exist?("/Applications/Ollama.app")
  else
    installed_version.nil? || version_less_than?(installed_version, latest_version)
  end

  package "aria2"

  # Download the DMG if update is needed
  execute "download ollama" do
    command "aria2c #{OLLAMA_URL} -d /tmp/ -o Ollama.dmg"
    only_if { needs_update }
    notifies :run, "execute[mount ollama dmg]", :immediately
  end

  # Mount the DMG
  execute "mount ollama dmg" do
    action :nothing
    command "hdiutil attach #{DMG_PATH} -nobrowse -quiet"
    notifies :run, "execute[install ollama]", :immediately
  end

  # Copy to /Applications
  execute "install ollama" do
    user "root"
    action :nothing
    command <<~EOCMD
      rm -rf "/Applications/#{APP_NAME}"
      cp -R "#{VOLUME}/#{APP_NAME}" "/Applications/"
    EOCMD
    notifies :run, "execute[unmount ollama dmg]", :immediately
  end

  # Unmount the DMG
  execute "unmount ollama dmg" do
    action :nothing
    command "hdiutil detach '#{VOLUME}' -quiet"
    notifies :run, "execute[remove ollama dmg]", :immediately
  end

  # Cleanup
  execute "remove ollama dmg" do
    action :nothing
    command "rm -f #{DMG_PATH}"
  end

  # Ensure the CLI symlink points at the CLI, not the GUI binary.
  # The guard compares the current target so a wrong pre-existing link is
  # repaired. sudo lives in the command rather than in `user "root"` so the
  # guard can run unprivileged: otherwise a password is demanded on every
  # deploy even when the link is already correct.
  execute "symlink ollama cli" do
    command "sudo ln -sfn '#{CLI_BINARY}' #{SYMLINK_PATH}"
    not_if "[ \"$(readlink #{SYMLINK_PATH} 2>/dev/null)\" = '#{CLI_BINARY}' ]"
  end

  # ---- model storage on the external SSD --------------------------------
  models_volume_ready = File.directory?(MODEL_PATH)
  unless models_volume_ready
    MItamae.logger.warn <<~EOWARN
      #{MODEL_VOLUME} is not mounted (or #{MODEL_PATH} is missing).
      Skipping the ~/.ollama/models symlink. Ollama will fall back to its
      default models directory and previously pulled models will look missing
      until the drive is mounted and this recipe is re-run.
    EOWARN
  end

  # (1) launchd session environment. launch_env writes a RunAtLoad
  # LaunchAgent per variable so the value survives reboots.
  launch_env "OLLAMA_MODELS" do
    value MODEL_PATH
    persistent true
  end

  # Tuning carried over from the retired com.ollama.serve agent.
  launch_env "OLLAMA_FLASH_ATTENTION" do
    value "1"
    persistent true
  end

  launch_env "OLLAMA_KV_CACHE_TYPE" do
    value "q4_0"
    persistent true
  end

  # (2) symlink fallback so the SSD is used even if the env var loses the
  # startup race. rmdir only succeeds on empty directories, so this can never
  # delete pulled models in the default location.
  execute "link ollama models to external ssd" do
    command <<~EOCMD
      set -e
      if [ -d '#{DEFAULT_MODELS}' ] && [ ! -L '#{DEFAULT_MODELS}' ]; then
        rmdir '#{DEFAULT_MODELS}/blobs' '#{DEFAULT_MODELS}/manifests' 2>/dev/null || true
        rmdir '#{DEFAULT_MODELS}' 2>/dev/null || true
      fi
      if [ -d '#{DEFAULT_MODELS}' ] && [ ! -L '#{DEFAULT_MODELS}' ]; then
        echo "skipping: #{DEFAULT_MODELS} is a non-empty directory; OLLAMA_MODELS still points at the SSD"
        exit 0
      fi
      ln -sfn '#{MODEL_PATH}' '#{DEFAULT_MODELS}'
    EOCMD
    only_if { models_volume_ready }
    not_if "[ \"$(readlink '#{DEFAULT_MODELS}' 2>/dev/null)\" = '#{MODEL_PATH}' ]"
  end

  # ---- remove the retired competing agent -------------------------------
  # Earlier versions of this cookbook installed com.ollama.serve. It still
  # auto-loads on machines that ran them, so remove it rather than leave it to
  # fight the app for port 11434.
  execute "remove legacy com.ollama.serve launchagent" do
    command <<~EOCMD
      launchctl bootout gui/$(id -u)/#{LEGACY_LABEL} 2>/dev/null || true
      launchctl unload '#{LEGACY_AGENT}' 2>/dev/null || true
      rm -f '#{LEGACY_AGENT}' '#{LEGACY_AGENT}.disabled'
    EOCMD
    not_if "[ ! -f '#{LEGACY_AGENT}' ] && [ ! -f '#{LEGACY_AGENT}.disabled' ]"
  end

  # ---- converge a running server onto the SSD path ----------------------
  # The app only reads OLLAMA_MODELS when it spawns the server, so a server
  # that is already running keeps its old environment until restarted.
  user_uid = run_command("id -u #{node[:user]}", error: false).stdout.strip

  execute "restart ollama server on external models path" do
    command "launchctl kickstart -k gui/#{user_uid}/#{APP_LABEL}"
    user node[:user]
    only_if "launchctl print gui/#{user_uid}/#{APP_LABEL} > /dev/null 2>&1"
    not_if "ps eww -p $(pgrep -f 'Resources/ollama serve' | head -1) 2>/dev/null | grep -q 'OLLAMA_MODELS=#{MODEL_PATH}'"
  end

  zshrc_config = node[:zshrc_config]

  # Interactive shells get the same path; this does not affect the server,
  # which is launchd-started and never reads ~/.zshrc.
  file zshrc_config do
    action :edit
    not_if "grep -q 'export OLLAMA_MODELS=#{MODEL_PATH}' #{zshrc_config} 2>/dev/null"
    content <<~CONTENT
      if [[ $OSTYPE == darwin* ]] && [[ -d #{MODEL_PATH} ]]; then
        export OLLAMA_MODELS=#{MODEL_PATH}
      fi
    CONTENT
  end
end
