include_recipe "./dependency.rb"
include_cookbook "uv"
include_cookbook "mise"

node.reverse_merge!(
  python: {
    version: "latest"
  }
)

user = node[:user]
home = node[:home]

remote_file "#{home}/.default-python-packages" do
  source "files/.default-python-packages"
  owner user
  mode "644"
end

execute "install python via mise" do
  user user
  command "mise use -g python@#{node[:python][:version]} && mise reshim"
  not_if "which python"
end
