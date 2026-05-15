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
    not_if { run_command("gh version", error: false).exit_status == 0 }
  end
end

# Install GitHub CLI via mise
unless rasppi?
  execute "install github-cli" do
    user node[:user]
    command "mise use -g gh@#{node[:github_cli][:version]}"
    not_if { run_command("mise exec -- gh version", error: false).exit_status == 0 }
  end
end

# Authenticate with GitHub CLI (must be done manually - it's interactive)
unless node[:platform] == "windows"
  result = run_command("mise exec -- gh auth status", error: false)
  if result.exit_status != 0 || result.stdout !~ /Logged in to github.com/
    MItamae.logger.info "Run 'gh auth login --git-protocol ssh --hostname github.com' to authenticate with GitHub"
  end
end

execute "gh_request_ssh_authoritation" do
  user node[:user]
  command "mise exec -- gh auth refresh -h github.com -s admin:public_key"
  only_if {
    result = run_command("mise exec -- gh ssh-key list", error: false)
    result.exit_status != 0 && result.stderr =~ /This API operation needs the "admin:public_key" scope/
  }
end
execute "gh_request_ssh_public_key" do
  user node[:user]
  command "mise exec -- gh auth refresh -h github.com -s admin:ssh_signing_key"
  only_if {
    result = run_command("mise exec -- gh ssh-key list", error: false)
    result.exit_status != 0 && result.stderr =~ /To request it, run:  gh auth refresh -h github.com -s admin:ssh_signing_key/
  }
end
