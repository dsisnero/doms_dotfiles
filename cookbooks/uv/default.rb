include_cookbook "mise"

mise "uv"

execute "install aider" do
  command <<~EOCMD
    mise exec -- uv tool install --force --python python3.12 aider-chat
  EOCMD
  not_if %(which aider )
end

execute "install docling" do
  command <<~EOCMD
    mise exec -- uv tool install --with docling  docling-slim
  EOCMD
  not_if %(which docling)
end

execute "install llm" do
  command <<~EOCMD
    mise exec -- uv tool install llm
  EOCMD
  not_if %(which llm)
end

zshrc_config = node[:zshrc_config]
user_bin = node[:user_bin]
file zshrc_config do
  action :edit
  not_if "grep 'export PATH=#{user_bin}' #{zshrc_config}"
  content %(export PATH=#{user_bin}:$PATH)
end
