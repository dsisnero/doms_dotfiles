# frozen_string_literal: true

include_cookbook "mise"

user = node["user"]
home = node["home"]

node.reverse_merge!(
  ghq: {
    version: "latest"
  }
)

execute "install ghq" do
  user user
  command "mise use -g ghq@#{node[:ghq][:version]}"
  not_if "test -e #{home}/.local/share/mise/installs/ghq/current"
end

# Ensure SSH agent socket directory exists
directory "#{home}/.ssh" do
  owner user
  group node[:group]
  mode "700"
end

# Create SSH agent environment file
file "#{home}/.ssh/agent_env" do
  owner user
  group node[:group]
  mode "600"
  content <<~EOCFG
    export SSH_AUTH_SOCK=#{home}/.ssh/agent.sock
    alias ssh-agent='eval $(ssh-agent -s -a #{home}/.ssh/agent.sock)'
  EOCFG
end

ghq_root = run_command(run_as(user, "ghq root")).stdout.chomp
node.reverse_merge!(
  ghq_root: ghq_root
)
