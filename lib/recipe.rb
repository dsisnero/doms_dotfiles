# Set platform override early
MItamae.logger.info "Detected platform: #{node[:platform].inspect}"
# Ensure OS is consistent with platform changes
include_recipe "recipe_helper"
include_role node[:platform]
