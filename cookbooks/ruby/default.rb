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
  command "mise settings ruby.compile=false"
end

node[:ruby][:version] || "latest"

remote_file "#{home}/.default-gems" do
  source "files/.default-gems"
  owner user
  mode "644"
end

mise "ruby"

home = node[:home]
dotfiles = node[:doms_dotfiles]
dst = "#{home}/.rake"
src = "#{dotfiles}/cookbooks/ruby/files/rake"

link dst do
  to src
  not_if { File.directory? dst }
end
