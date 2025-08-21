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
  not_if { run_command('gh version', error: false).exit_status == 0 }
end

# Authenticate with GitHub CLI
execute "gh_auth_login" do
  user node[:user]
  command "gh auth login --git-protocol ssh --hostname github.com"
  not_if { run_command("gh auth status").stdout =~ /Logged in to github.com/ }
end

execute 'gh_request_ssh_authoritation' do
  user node[:user]
  command "gh auth refresh -h github.com -s admin:public_key"
  only_if {
    result = run_command('gh ssh-key list', error: false)
    result.exit_status != 0 && result.stderr =~ /This API operation needs the "admin:public_key" scope/
  }
end
execute 'gh_request_ssh_public_key' do
  user node[:user]
  command "gh auth refresh -h github.com -s admin:ssh_signing_key"
  only_if {
    result = run_command('gh ssh-key list', error: false)
    result.exit_status != 0 && result.stderr =~ /To request it, run:  gh auth refresh -h github.com -s admin:ssh_signing_key/
  }
end
