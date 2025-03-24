include_cookbook "github-cli"

node.reverse_merge!(
  github: {
    ssh_key_type: "ed25519",
    ssh_key_file: "id_github",
    email: "dsisnero@gmail.com" # ← MUST CHANGE THIS
  }
)
include_cookbook "ssh"

# Create .ssh directory if missing
directory "#{node[:home]}/.ssh" do
  owner node[:user]
  mode "700"
  not_if "test -d #{node[:home]}/.ssh"
end

# Generate GitHub-specific SSH key
execute "generate GitHub SSH key" do
  user node[:user]
  command <<-EOCMD
    ssh-keygen -t #{node[:github][:ssh_key_type]} \
    -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]} \
    -C "#{node[:github][:email]}" \
    -N ""
  EOCMD
  not_if "test -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}"
end

# Configure SSH agent
execute "start ssh-agent" do
  user node[:user]
  command "eval $(ssh-agent -s)"
  not_if "pidof ssh-agent"
end

execute "add GitHub key to agent" do
  user node[:user]
  command "SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock ssh-add #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}"
  not_if "SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock ssh-add -l | grep -q #{node[:github][:ssh_key_file]}"
end

# Display public key instructions
execute "show GitHub SSH public key" do
  user node[:user]
  command <<~EOCMD
    if command -v gh >/dev/null; then
      echo "✅ GitHub CLI authenticated for: $(gh api user | jq -r .login)"
    else
      echo "⚠️  GitHub CLI not installed - manual key copy required"
    fi

    echo "🔑 SSH Public Key:"
    echo "------------------"
    cat #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub
    echo "------------------"
    
    # Clipboard copy commands
    if command -v xclip >/dev/null; then
      cat #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub | xclip -selection clipboard
      echo "📋 Key copied to clipboard (Linux)"
    elif command -v pbcopy >/dev/null; then
      cat #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub | pbcopy
      echo "📋 Key copied to clipboard (macOS)"
    fi

    echo "🌐 Add this key to GitHub:"
    echo "   1. Go to https://github.com/settings/keys"
    echo "   2. Click 'New SSH key'"
    echo "   3. Paste key contents"
    echo "   4. Click 'Add SSH key'"
  EOCMD
  only_if "test -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub"
end

# Add automatic key upload via GitHub CLI
execute "add_ssh_key_via_gh" do
  user node[:user]
  command <<~EOCMD
    gh ssh-key add #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub \\
      --title "#{node[:hostname]} [$(date +%F)]" \\
      --type authentication
  EOCMD
  not_if "gh ssh-key list | grep -qF '$(cat #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub | cut -d' ' -f2)'"
  only_if "which gh && gh auth status >/dev/null 2>&1"
end

# Verify SSH connection
execute "test GitHub SSH connection" do
  user node[:user]
  command "SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock ssh -T git@github.com"
  only_if "test -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}"
end
