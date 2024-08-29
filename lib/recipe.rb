class Specinfra::Command::Pop < Specinfra::Command::Ubuntu
end
include_recipe "recipe_helper"

node[:platform] = "ubuntu" if node[:platform] == "pop"
include_role node[:platform]
