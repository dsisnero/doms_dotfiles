include_recipe "./dependency.rb"
include_cookbook "uv"
version = "latest"
# version = node[:python][:version] unless node[:python].nil?
version = "3.13.0"

user = node[:user]
home = node[:home]

remote_file "#{home}/.default-python-packages" do
  source "files/.default-python-packages"
  owner user
  mode "644"
end

[
  {cmd: "asdf plugin add python https://github.com/asdf-community/asdf-python.git",
   not_if: "asdf plugin list | grep python"},
  {cmd: "asdf install python #{version}", not_if: "asdf list python | grep #{version}"},
  {cmd: "asdf global python #{version}", not_if: "which python"}
].each do |op|
  source_asdf_and_execute op[:cmd] do
    user user
    not_if_ op[:not_if] unless op[:not_if].nil?
  end
end
