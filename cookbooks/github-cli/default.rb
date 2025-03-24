include_cookbook "mise"

node.reverse_merge!(
  github_cli: {
    version: "latest"
  }
)

# Install GitHub CLI via mise
execute "install github-cli" do
  user node[:user]
  command "mise use -g gh@#{node[:github_cli][:version]}"
  not_if "which gh"
end

# Authenticate with GitHub CLI
execute "gh_auth_login" do
  user node[:user]
  command "gh auth login --git-protocol ssh --hostname github.com"
  not_if "gh auth status >/dev/null 2>&1"
  only_if "which gh"
end
