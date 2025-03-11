include_recipe "./dependency.rb"
include_cookbook "./mise"

# node.reverse_merge!({
#   nodejs: {
#     version: '10.13.0',
#   }
# })
execute "install node" do
  user node[:user]
  command "mise use -g node"
end
