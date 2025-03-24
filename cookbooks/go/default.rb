# frozen_string_literal: true

include_cookbook "mise"

node.reverse_merge!(
  go: {
    version: "latest"
  },
  go_root: "#{node[:home]}/.local/share/mise/installs/go/current/go"
)

execute "install go via mise" do
  user node[:user]
  command "mise use -g go@#{node[:go][:version]} && mise reshim"
  not_if "which go"
end

# Reimplement go_get definition
define :go_get do
  reponame = params[:name]
  
  execute "#{node[:go_root]}/go install #{reponame}@#{node[:go][:version]}" do
    user node[:user]
  end
end
