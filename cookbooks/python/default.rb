include_recipe "./dependency.rb"
include_cookbook "uv"
include_cookbook "mise"

version = node[:python][:version]
version ||= "latest"

user = node[:user]
home = node[:home]

remote_file "#{home}/.default-python-packages" do
  source "files/.default-python-packages"
  owner user
  mode "644"
end

execute "install latest python" do
  user user
  command %(mise use -g python@#{version})
end

# [
#   {cmd: "asdf plugin add python https://github.com/asdf-community/asdf-python.git",
#    not_if: "asdf plugin list | grep python"},
#   {cmd: "asdf install python #{version}", not_if: "asdf list python | grep #{version}"},
#   {cmd: "asdf global python #{version}", not_if: "which python"}
# ].each do |op|
#   source_asdf_and_execute op[:cmd] do
#     user user
#     not_if_ op[:not_if] unless op[:not_if].nil?
#   end
# end
