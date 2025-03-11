include_recipe "dependency.rb"
include_cookbook "./mise"

version = "latest"
version = node[:deno][:version] unless node[:deno].nil?
user = node[:user]
home = node[:home]

execute "install deno" do
  user user
  command "mise use -g deno@#{version}"
end
