# cookbook for ruby
include_recipe "./dependency.rb"

user = node["user"]
home = node["home"]
version = "latest"

remote_file "#{home}/.default-gems" do
  source "files/.default-gems"
  owner user
  mode "644"
end

execute "install asdf-ruby" do
  user user
  command <<~EOS
    . /etc/profile.d/asdf.sh
    asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
  EOS
  not_if "test -d #{home}/.asdf/plugins/ruby"
end

[
  {cmd: "asdf plugin add ruby", not_if: "asdf plugin list | grep ruby"},
  {cmd: "asdf install ruby #{version}", not_if: "asdf list ruby | grep #{version}"},
  {cmd: "asdf global ruby #{version}"},
  {cmd: "asdf reshim ruby"}
].each do |op|
  source_asdf_and_execute op[:cmd] do
    user user
    not_if_ op[:not_if] unless op[:not_if].nil?
  end
end
