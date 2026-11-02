case node[:platform]
when "darwin", "osx"
  package "opencode"
when "windows"
  log "Not implemented"
else
  include_cookbook "mise"

  mise "@opencode/cli" do
    backend "npm"
    exe "opencode"
  end
end
