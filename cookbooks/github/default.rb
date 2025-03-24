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
  command "SET SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock source #{node[:home]}/.ssh/agent_env && ssh-add #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}"
  not_if "source #{node[:home]}/.ssh/agent_env && ssh-add -l | grep -q #{node[:github][:ssh_key_file]}"
end

# Display public key instructions
execute "show GitHub SSH public key" do
  user node[:user]
  command <<-EOCMD
    echo '=== ACTION REQUIRED ==='
    echo '1. Copy below public key:'
    echo '2. Go to https://github.com/settings/keys'
    echo '3. Click "New SSH key" and paste'
    echo '========================'
    cat #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}.pub
  EOCMD
end

# Verify SSH connection
execute "test GitHub SSH connection" do
  user node[:user]
  command "ssh -T git@github.com"
  only_if "test -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}"
end
