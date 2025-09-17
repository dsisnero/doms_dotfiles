external_drive = nil
case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  external_drive = "/mnt/extreme_ssd"
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
  mise "ollama"
  external_drive = "/Volumes/extreme_ssd"

  user_var = node["user"]
  home = node["home"]
  ollama_bin = "#{home}/.local/bin/ollama" # Assumes mise installs here; adjust if needed
  ollama_model_dir = File.join(external_drive, "ollama_models")

  launch_agents_dir = "#{home}/Library/LaunchAgents"
  plist_path = "#{launch_agents_dir}/com.ollama.server.plist"

  directory launch_agents_dir do
    owner user_var
    group "staff"
    mode "755"
  end

  file plist_path do
    content <<~EOPLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>com.ollama.server</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{ollama_bin}</string>
              <string>serve</string>
          </array>
          <key>EnvironmentVariables</key>
          <dict>
              <key>OLLAMA_MODELS</key>
              <string>#{ollama_model_dir}</string>
          </dict>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
          <key>StandardOutPath</key>
          <string>#{home}/Library/Logs/ollama.log</string>
          <key>StandardErrorPath</key>
          <string>#{home}/Library/Logs/ollama.log</string>
      </dict>
      </plist>
    EOPLIST
    owner user_var
    group "staff"
    mode "644"
    notifies :run, "execute[load ollama launchagent]"
  end

  execute "load ollama launchagent" do
    command "launchctl load -w #{plist_path}"
    user user_var
    action :nothing
  end

end
zshrc_config = node[:zshrc_config]
ollama_model_dir = File.join(external_drive, "ollama_models")

file zshrc_config do
  action :edit
  not_if %(grep "export OLLAMA_MODELS=#{ollama_model_dir}" #{zshrc_config})
  content %(export OLLAMA_MODELS=#{ollama_model_dir})
end
