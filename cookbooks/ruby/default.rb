# cookbook for ruby
include_recipe "./dependency.rb"
include_cookbook "mise"

user = node["user"]
home = node["home"]

node.reverse_merge!(
  ruby: {
    version: "latest"
  }
)
execute("set ruby to use prebuilt binaries for mise") do
  user user
end

version = node[:ruby][:version] || "latest"

remote_file "#{home}/.default-gems" do
  source "files/.default-gems"
  owner user
  mode "644"
end

execute "install latest ruby" do
  user user
  command %(#{home}/.local/bin/mise use -g ruby@#{version})
end

home = node[:home]
dotfiles = node[:doms_dotfiles]
dst = "#{home}/.rake"
src = "#{dotfiles}/cookbooks/ruby/files/rake"

link dst do
  to src
  not_if { File.directory? dst }
end
