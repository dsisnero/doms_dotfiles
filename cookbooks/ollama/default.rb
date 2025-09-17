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

end
zshrc_config = node[:zshrc_config]
ollama_model_dir = File.join(external_drive, "ollama_models")

file zshrc_config do
  action :edit
  not_if %(grep "export OLLAMA_MODELS=#{ollama_model_dir}" #{zshrc_config})
  content %(export OLLAMA_MODELS=#{ollama_model_dir})
end
