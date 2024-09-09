
home = node[:home]
user = node[:user]
cargo "alacritty" do
  user user
end

# copy alacritty desktop to files
share_dir = "#{home}/.local/share"
local_app_dir = "#{share_dir}/applications"

find_alacritty_desktop = `find ~/.cargo -name '*.desktop' -exec grep -l 'alacritty' {} +`.chomp
