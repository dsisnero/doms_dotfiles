# include_recipe "dependency.rb"

# Create SSH config
remote_file "#{node[:home]}/.ssh/config" do
  owner node[:user]
  mode "600"
  content <<~EOCFG
    Host github.com
      HostName github.com
      User git
      IdentityFile #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}
      IdentitiesOnly yes
      AddKeysToAgent yes
  EOCFG
  only_if "test -f #{node[:home]}/.ssh/#{node[:github][:ssh_key_file]}"
end
