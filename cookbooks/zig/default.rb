user = node[:user]
home = node[:home]
doms_dotfiles = node[:doms_dotfiles]
config_dir = node[:config_home]

include_cookbook "mise"

mise "zig"
