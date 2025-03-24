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

ghq_root = run_command(run_as(user, "ghq root")).stdout.chomp
node.reverse_merge!(
  ghq_root: ghq_root
)
