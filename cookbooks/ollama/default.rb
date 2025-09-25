include_cookbook "mise"
home = node[:home]
log_dir = "#{home}/.local/state/ollama"

OUTPUT_LOG = File.join(log_dir, "ollama.log")
ERROR_LOG = File.join(log_dir, "ollama_error.log")

mydir log_dir

url = case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  "https://ollama.com/download/ollama-linux-amd64.tgz"
when "darwin"
  "https://ollama.com/download/Ollama.dmg"
end
case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  user_var = node["user"]
  url = "https://ollama.com/download/ollama-linux-amd64.tgz"
  download_path = "/tmp/ollama-linux-amd64.tgz"
  home = node["home"]
  local = "#{home}/.local"
  http_request download_path do
    url url
    path download_path
    user user_var
    notifies :run, "execute[unzip ollama]"
    # not_if { File.exist? "#{home}.local/bin/ollama" }
    not_if "#{sudo(user_var)} which ollama"
  end

  execute "unzip ollama" do
    command <<~EOCMD
      tar -C #{local} -xzf #{download_path}
    EOCMD
    user user_var
    action :nothing
  end

when "darwin"
  #   mise "ollama"
  #   external_drive = "/Volumes/extreme_ssd"

  #   user_var = node["user"]
  #   home = node["home"] # Assumes mise installs here; adjust if needed
  #   ollama_model_dir = File.join(external_drive, "ollama_models")

  #   launch_agents_dir = "#{home}/Library/LaunchAgents"
  #   plist_path = "#{launch_agents_dir}/com.ollama.server.plist"

  #   directory launch_agents_dir do
  #     owner user_var
  #     group "staff"
  #     mode "755"
  #   end

  #   output_log = File.join(log_dir, "ollama.log")
  #   error_log = File.join(log_dir, "ollama_error.log")

  #   template plist_path do
  #     source "templates/ollama.plist.erb"
  #     owner node[:user]
  #     group node[:group]
  #     mode "644"
  #     variables(
  #       user_home: node[:home],
  #       models_dir: ollama_model_dir,
  #       ollama_output_log: output_log,
  #       ollama_error_log: error_log
  #     )
  #     notifies :run, "execute[load ollama launchagent]"
  #   end

  #   execute "load ollama launchagent" do
  #     command "launchctl load -w #{plist_path}"
  #     user user_var
  #     action :nothing
  #   end

  # end
  # zshrc_config = node[:zshrc_config]
  # ollama_model_dir = File.join(external_drive, "ollama_models")

  # file zshrc_config do
  #   action :edit
  #   not_if %(grep "export OLLAMA_MODELS=#{ollama_model_dir}" #{zshrc_config})
  #   content %(export OLLAMA_MODELS=#{ollama_model_dir})
  # end

  # ### when darwin
  # # ollama.rb
  # #
  # # Installs Ollama.app, symlinks CLI, and configures it
  # # to run headless with external model storage at login.
  # # Adds lifecycle controls (start/stop/restart) via launchctl.

  OLLAMA_URL = "https://ollama.com/download/Ollama.dmg"
  DMG_PATH = "/tmp/Ollama.dmg"
  VOLUME = "/Volumes/Ollama"
  APP_NAME = "Ollama.app"
  DEST_APP = "/Applications/#{APP_NAME}"
  PLIST_PATH = "#{DEST_APP}/Contents/Info.plist"
  DESIRED_VERSION = "0.4.0" # update as new releases come out
  SYMLINK_PATH = "/usr/local/bin/ollama"
  LAUNCH_AGENT = "#{home}/Library/LaunchAgents/com.ollama.serve.plist"
  SYSTEM_LAUNCH_AGENT = "/Library/LaunchDaemons/com.ollama.serve.plist"
  MODEL_PATH = "/Volumes/extreme_ssd/ollama_models"
  LABEL = "com.ollama.serve"

  # Helper: check installed version
  # def installed_version
  #   cmd = "defaults read '#{PLIST_PATH}' CFBundleShortVersionString 2>/dev/null"
  #   begin
  #     `#{cmd}`.strip
  #   rescue
  #     nil
  #   end
  # end
  package "aria2"
  # needs_update = installed_version != DESIRED_VERSION

  # Download the DMG if update is needed
  execute "download ollama" do
    command "aria2c #{OLLAMA_URL} -d /tmp/ -o Ollama.dmg"
    # only_if { needs_update }
    only_if { true }
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
    command "cp -R '#{VOLUME}/#{APP_NAME}' /Applications/"
    not_if { Dir.exist? "/Applications/#{APP_NAME}" }
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

  # Ensure CLI symlink exists
  execute "symlink ollama cli" do
    user "root"
    command "ln -sf /Applications/Ollama.app/Contents/MacOS/Ollama #{SYMLINK_PATH}"
    not_if "test -x #{SYMLINK_PATH}"
  end

  # LaunchAgent plist for headless ollama serve
  template LAUNCH_AGENT do
    source "templates/ollama.plist.erb"
    owner node[:user]
    group node[:group]
    mode "644"
    variables(
      ollama_label: LABEL,
      ollama_path: SYMLINK_PATH,
      user_home: node[:home],
      model_path: MODEL_PATH,
      ollama_output_log: OUTPUT_LOG,
      ollama_error_log: ERROR_LOG
    )
    notifies :run, "execute[load ollama serve plist]", :immediately
  end

  # template SYSTEM_LAUNCH_AGENT do
  #   source "templates/ollama.plist.erb"
  #   owner "root"
  #   group "wheel"
  #   mode "644"
  #   variables(
  #     ollama_label: LABEL,
  #     ollama_path: SYMLINK_PATH,
  #     user_home: node[:home],
  #     model_path: MODEL_PATH,
  #     ollama_output_log: OUTPUT_LOG,
  #     ollama_error_log: ERROR_LOG
  #   )
  #   notifies :run, "execute[load ollama serve plist root]", :immediately
  # end

  zshrc_config = node[:zshrc_config]

  file zshrc_config do
    action :edit
    not_if %(grep "alias ollama:start='sudo launchctl load #{LAUNCH_AGENT}'}" #{zshrc_config})
    content <<~CONTENT
      alias ollama:start='sudo launchctl load #{LAUNCH_AGENT}'
      alias ollama:stop='sudo launchctl unload #{LAUNCH_AGENT}'
    CONTENT
  end

  # Load LaunchAgent (start at login)
  execute "load ollama serve plist" do
    action :nothing
    command "launchctl load -w #{LAUNCH_AGENT}"
  end

  execute "load ollama serve plist root" do
    action :nothing
    command "launchctl load -w #{LAUNCH_AGENT}"
  end

  # --- Lifecycle management ---
  execute "start ollama" do
    action :nothing
    command "launchctl start #{LABEL}"
  end

  execute "stop ollama" do
    action :nothing
    command "launchctl stop #{LABEL}"
  end

  execute "restart ollama" do
    action :nothing
    command "launchctl stop #{LABEL} && launchctl start #{LABEL}"
  end
end
