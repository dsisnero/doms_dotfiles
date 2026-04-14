include_recipe "dependency.rb"
include_cookbook "mise"

node.reverse_merge!(
  neovim: {
    version: "stable"
  }
)

config_home = node[:config_home]

case node[:platform]
when "darwin"
  package "neovim"
else
  mise "neovim" do
    backend "aqua"
    exe "nvim"
  end
end

include_cookbook "ghq"

my_repos = node[:my_repos]

get_repo("dsisnero/astronvim_config")

src = File.join(my_repos, "astronvim_config")
dst = File.join(config_home, "nvim")

link dst do
  to src
  user node[:user]
  not_if { File.directory? dst }
end
