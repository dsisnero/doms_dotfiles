include_recipe "dependency.rb"
include_cookbook "mise"

node.reverse_merge!(
  neovim: {
    version: "stable"
  }
)

config_home = node[:config_home]

execute "install neovim via mise" do
  user node[:user]
  command "mise use -g neovim@#{node[:neovim][:version]}"
  not_if "which nvim"
end

include_cookbook "ghq"

my_repos = node[:my_repos]

get_repo("dsisnero/nvim")

src = File.join(my_repos, "astronvim_config")
dst = File.join(config_home, "nvim")

link dst do
  to src
  user node[:user]
  not_if { File.directory? dst }
end
