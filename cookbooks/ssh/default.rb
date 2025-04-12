# SSH configuration
directory "#{node[:home]}/.ssh" do
  owner node[:user]
  group node[:group]
  mode "700"
end

# Start SSH agent with persistent socket
execute "start ssh-agent" do
  user node[:user]
  command "ssh-agent -a #{node[:home]}/.ssh/agent.sock"
  not_if "test -S #{node[:home]}/.ssh/agent.sock"
end

# Verify SSH agent has keys loaded
execute "verify ssh-agent" do
  user node[:user]
  command "SSH_AUTH_SOCK=#{node[:home]}/.ssh/agent.sock ssh-add -l"
  only_if "test -S #{node[:home]}/.ssh/agent.sock"
end
