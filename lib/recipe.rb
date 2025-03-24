include_recipe "recipe_helper"

# FINALLY set platform override
node[:platform] = "ubuntu" if node[:platform] == "pop"
include_role node[:platform]
