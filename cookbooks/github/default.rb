include_cookbook "github-cli"

node.reverse_merge!(
  github: {
    ssh_key_type: "ed25519",
    ssh_key_file: "id_github",
    email: "dsisnero@gmail.com"
  }
)

# Start SSH agent with persistent socket
execute "start ssh-agent" do
  user node[:user]
  command "ssh-agent -a #{node[:home]}/.ssh/agent.sock"
  not_if "test -S #{node[:home]}/.ssh/agent.sock"
end

directory "#{node[:home]}/.ssh" do
  owner node[:user]
  group node[:group]
  mode "700"
  not_if "test -d #{node[:home]}/.ssh"
end

keyfile = "#{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}"

execute "add-github-key-to-agent" do
  command "ssh_auth_sock=#{node[:home]}/.ssh/agent.sock ssh-add #{keyfile}"
  user node[:user]
  action :nothing
  notifies :run, 'execute[verify ssh-agent]'
end

execute "generate GitHub SSH key #{keyfile}" do
  user node[:user]
  command <<~EOCMD
    ssh-keygen -t #{node[:github][:ssh_key_type]} \
    -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]} \
    -C "#{node[:github][:email]}" \
    -N "" -q
  EOCMD
  not_if "test -f #{keyfile}"
  notifies :run, 'execute[add-github-key-to-agent]'
end

file "#{node[:home]}/.ssh/config" do
  owner node[:user]
  group node[:group]
  mode "600"
  content <<~EOCFG
    Host github.com
      HostName github.com
      User git
      IdentityFile #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}
      IdentityAgent #{node[:home]}/.ssh/agent.sock
      IdentitiesOnly yes
      AddKeysToAgent yes
  EOCFG
  only_if "test -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}"
end

# Verify SSH agent has keys loaded
execute "verify ssh-agent" do
  user node[:user]
  command "SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock ssh-add -l"
  action :nothing
end

execute "show GitHub SSH public key" do
  user node[:user]
  command <<~EOCMD
    if command -v gh >/dev/null && gh auth status >/dev/null; then
      echo "✅ GitHub CLI authenticated for: $(gh api user | jq -r .login)"
    else
      echo "⚠️  GitHub CLI not installed or not authenticated"
    fi

    echo "🔑 SSH Public Key:"
    echo "------------------"
    cat #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub
    echo "------------------"
    if command -v xclip >/dev/null 2>&1; then
      cat #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub | xclip -selection clipboard
      echo "📋 Key copied to clipboard (Linux)"
    elif command -v pbcopy >/dev/null 2>&1; then
      cat #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub | pbcopy
      echo "📋 Key copied to clipboard (macOS)"
    fi

    echo "🌐 Add this key to GitHub: https://github.com/settings/keys"
  EOCMD
  only_if "test -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub"
end

execute "add_ssh_key_via_gh" do
  user node[:user]
  command <<~EOCMD
    gh ssh-key add #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub \
      --title "#{node[:hostname]} [$(date +%F)]" \
      --type authentication
  EOCMD
  not_if <<~EOCMD
    if which gh >/dev/null && gh auth status >/dev/null; then
      fingerprint=$(ssh-keygen -lf #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]} | awk '{print $2}')
      gh ssh-key list | grep -qF "$fingerprint"
    else
      exit 1
    fi
  EOCMD
end

# execute "test GitHub SSH connection" do
#   user node[:user]
#   command "SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock ssh -T git@github.com"
#   only_if <<~EOCMD
#     test -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]} && \
#     SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock ssh-add -l | grep -q $(ssh-keygen -lf #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]} | awk '{print $2}')
#   EOCMD
# end
