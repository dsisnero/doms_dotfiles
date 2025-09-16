include_recipe "./dependency.rb"
include_cookbook "./mise"

user = node["user"]
home = node["home"]

# node.reverse_merge!({
#   nodejs: {
#     version: '10.13.0',
#   }
# })

remote_file "#{home}/.default-npm-packages" do
  source "files/.default-npm-packages"
  owner user
  mode "644"
end

node.reverse_merge!(
  node: {
    version: "latest"
  }
)
version = node[:node][:version] || "latest"

execute "install node" do
  user node[:user]
  command "mise use -g node@#{version}"
end
