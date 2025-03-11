# frozen_string_literal: true

include_cookbook "mise"

version = "latest"

user = node["user"]
home = node["home"]

execute "install ghq" do
  user user
  command <<EOCMD
  VER=#{version}
  mise use -g ghq@${VER} 
EOCMD
  # not_if "test -e ~/.asdf/shims/ghq"
end

ghq_root = run_command(run_as(user, "ghq root")).stdout.chomp
node.reverse_merge!(
  ghq_root: ghq_root
)
