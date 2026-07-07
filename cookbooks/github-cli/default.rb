include_cookbook "mise"

node.reverse_merge!(
  github_cli: {
    version: "latest"
  }
)
if rasppi?

  # Fallback to manual installation if apt_repository resource not available
  execute "install github-cli via official script" do
    command <<-EOH
        (type -p wget >/dev/null || (apt update && apt install wget -y)) \
        && mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && mkdir -p -m 755 /etc/apt/sources.list.d \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && apt update \
        && apt install gh -y
    EOH
    user "root"
    not_if "which gh"
  end
end

# Install GitHub CLI via mise
unless rasppi?
  execute "install github-cli" do
    user node[:user]
    command "mise use -g gh@#{node[:github_cli][:version]}"
    not_if "mise exec -- which gh"
  end
end

# Determine gh command prefix (mise-managed or system)
gh_cmd = rasppi? ? "gh" : "mise exec -- gh"

# Authentication must be done interactively by the user:
#   gh auth login --git-protocol ssh --hostname github.com
MItamae.logger.info "Skipping gh auth login — authenticate manually with: gh auth login --git-protocol ssh --hostname github.com"

execute "gh_request_ssh_authoritation" do
  user node[:user]
  command "#{gh_cmd} auth refresh -h github.com -s admin:public_key"
  only_if {
    result = run_command("#{gh_cmd} ssh-key list", error: false)
    result.exit_status != 0 && result.stderr =~ /This API operation needs the "admin:public_key" scope/
  }
end
execute "gh_request_ssh_public_key" do
  user node[:user]
  command "#{gh_cmd} auth refresh -h github.com -s admin:ssh_signing_key"
  only_if {
    result = run_command("#{gh_cmd} ssh-key list", error: false)
    result.exit_status != 0 && result.stderr =~ /To request it, run:  gh auth refresh -h github.com -s admin:ssh_signing_key/
  }
end

execute "setup git credentials with gh" do
  user node[:user]
  command "#{gh_cmd} auth setup-git"
  only_if "#{gh_cmd} auth status 2>/dev/null | grep -q 'Logged in'"
end
