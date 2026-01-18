# Set platform override early
MItamae.logger.info "Detected platform: #{node[:platform].inspect}"
# Ensure OS is consistent with platform changes
include_recipe "recipe_helper"
if node[:platform] == "pop"
  node.reverse_merge!(
    platform: "ubuntu"
  )
end
include_role node[:platform]
