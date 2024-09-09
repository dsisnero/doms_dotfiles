
home = node[:home]
user = node[:user]
cargo "alacritty" do
  user user
end

# copy alacritty desktop to files
share_dir = "#{home}/.local/share"
local_app_dir = "#{share_dir}/applications"

find_alacritty_desktop = run_command("fd -e desktop alacritty", cwd: "#{home}/.cargo").stdout.chomp
