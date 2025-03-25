# Set platform override early
MItamae.logger.info "Detected platform: #{node[:platform].inspect}"
node[:platform] = "ubuntu" if node[:platform] == "pop"
MItamae.logger.info "Adjusted platform: #{node[:platform].inspect}"
include_recipe "recipe_helper"
include_recipe "node_supplement"
include_role node[:platform]
