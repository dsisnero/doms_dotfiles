# Show all node attributes in a formatted way
file "#{node[:home]}/node_attributes.txt" do
  content <<~CONTENT
    Platform: #{node[:platform]}
    Platform Family: #{node[:platform_family]}
    All Attributes:
    #{node.to_hash.to_yaml}
  CONTENT
  mode '644'
  owner node[:user]
end

# Print key attributes to stdout during run
execute "Show attributes" do
  command <<-CMD
    echo "Platform: #{node[:platform]}" 
    echo "Platform Family: #{node[:platform_family]}"
    echo "Full attributes saved to: #{node[:home]}/node_attributes.txt"
  CMD
end
