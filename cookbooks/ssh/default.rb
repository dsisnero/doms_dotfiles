# SSH configuration
directory "#{node[:home]}/.ssh" do
  owner node[:user]
  group node[:group]
  mode "700"
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

# Start SSH agent with persistent socket
execute "start ssh-agent" do
  user node[:user]
  command "ssh-agent -a #{node[:home]}/.ssh/agent.sock"
  not_if "test -S #{node[:home]}/.ssh/agent.sock"
end
