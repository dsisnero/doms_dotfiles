# cookbook for ruby
include_recipe "./dependency.rb"

user = node["user"]
home = node["home"]

node.reverse_merge!(
  ruby: {
    version: "latest"
  }
)

version = node[:ruby][:version] || "latest"

remote_file "#{home}/.default-gems" do
  source "files/.default-gems"
  owner user
  mode "644"
end

execute "install latest ruby" do
  user user
  command %(mise use -g ruby@#{version})
end

dotfile_repo = node[:dotfile_repo]
home = node[:home]
dst "#{home}/rake"
src = "rake"

link dst do
  to src
  not if "test -d #{dst}"
end
