# Set platform override early
node[:platform] = "ubuntu" if node[:platform] == "pop"
include_recipe "recipe_helper"
include_recipe "node_supplement"
include_role node[:platform]
