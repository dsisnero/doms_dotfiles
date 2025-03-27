# Set platform override early
MItamae.logger.info "Detected platform: #{node[:platform].inspect}"
node[:platform] = "ubuntu" if node[:platform] = "pop"
# Ensure OS is consistent with platform changes
include_recipe "node_supplement"
include_recipe "recipe_helper"
include_role node[:platform]
