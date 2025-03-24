# frozen_string_literal: true

include_cookbook "mise"

execute "install go" do
  user node[:user]
  command "mise use -g go"
end

# Add new node configuration
node.reverse_merge!(
  go_root: "#{node[:home]}/.local/share/mise/installs/go/current/go"
)

# Reimplement go_get definition
define :go_get do
  reponame = params[:name]
  version = "latest"

  execute "#{node[:go_root]}/go install #{reponame}@#{version}" do
    user node[:user]
  end
end
