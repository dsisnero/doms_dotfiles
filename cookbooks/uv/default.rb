include_cookbook "mise"

mise "uv"

user_ = node[:user]
home_ = node[:home]

execute "fix uv cache ownership" do
  command "chown -R #{user_}:$(id -gn #{user_}) #{home_}/.cache/uv #{home_}/.local/share/uv"
  only_if do
    File.directory?("#{home_}/.cache/uv") && !run_command("test -O #{home_}/.cache/uv", error: false).success?
  end
end

completions_dir = "#{node[:doms_dotfiles]}/config/zsh/functions/completions"

execute "generate uv zsh completions" do
  command "uv generate-shell-completion zsh > #{completions_dir}/_uv"
  user user_
  not_if "test -f #{completions_dir}/_uv"
end

execute "install aider" do
  command <<~EOCMD
    mise exec -- uv tool install --force --python python3.12 aider-chat
  EOCMD
  user user_
  not_if %(which aider )
end

execute "install docling" do
  command <<~EOCMD
    mise exec -- uv tool install --with docling  docling-slim
  EOCMD
  user user_
  not_if %(which docling)
end

execute "install llm" do
  command <<~EOCMD
    mise exec -- uv tool install llm
  EOCMD
  user user_
  not_if %(which llm)
end

zshrc_config = node[:zshrc_config]
user_bin = node[:user_bin]
file zshrc_config do
  action :edit
  not_if "grep 'export PATH=#{user_bin}' #{zshrc_config}"
  content %(export PATH=#{user_bin}:$PATH)
end
