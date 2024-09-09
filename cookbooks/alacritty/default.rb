home = node[:home]
user = node[:user]
cargo "alacritty" do
  user user
end

# copy alacritty desktop to files
share_dir = "#{home}/.local/share"
local_app_dir = "#{share_dir}/applications"
# find_alacritty_desktop = run_command("fd -e desktop alacritty", cwd: "#{home}/.cargo").stdout.chomp
find_alacritty_desktop = run_command("find . -name '*.desktop' -exec grep -l 'alacritty' {} +", cwd: "#{home}/.cargo").stdout.chomp
unless find_alacritty_desktop.empty?

  MItamae.logger.info("alacritty desktop found at  #{find_alacritty_desktop}")
  alacritty_desktop_src = File.join(home, ".cargo", find_alacritty_desktop)
  alacritty_desktop_dest = File.join(local_app_dir, File.basename(alacritty_desktop_src))
  icon = Dir.glob("#{home}/.cargo/**/alacritty-term.svg").first
  icon_dest = File.join(share_dir, "icons", File.basename(icon))
  alacritty_cmd = "#{home}/.cargo/bin/alacritty"

  execute "copy alacritty desktop to ~/.local/share/applications" do
    user user
    command "cp #{alacritty_desktop_src} #{local_app_dir}"
    not_if "test -f #{alacritty_desktop_dest}"
  end

  file alacritty_desktop_dest do
    action :edit
    block do |content|
      content.gsub!(/Exec=[a,A]lacritty %F/, "Exec=#{alacritty_cmd}")
      content.gsub!(/Exec=[a,A]lacritty$/, "Exec=#{alacritty_cmd}")
      content.gsub!(/Icon=[a,A]lacritty$/, "Icon=#{icon_dest}")
      content.gsub!(/TryExec=[a,A]lacritty %F/, "Exec=#{alacritty_cmd}")
      content.gsub!(/TryExec=[a,A]lacritty$/, "Exec=#{alacritty_cmd}")
    end
    owner user
    group user
    not_if "grep 'Icon=#{icon_dest}' #{alacritty_desktop_dest}"
  end

  execute "cp #{icon} #{share_dir}/icons" do
    user user
    not_if "test -f #{icon_dest}"
  end
end
