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
    mise exec -- uv tool install docling
  EOCMD
  not_if %(which docling)
end

execute "install llm" do
  command <<~EOCMD
    mise exec -- uv tool install llm
  EOCMD
  not_if %(which llm)
end
