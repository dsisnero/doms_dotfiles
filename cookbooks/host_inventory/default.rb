keys = [
  :memory,
  # :ec2,
  :hostname,
  # :domain,
  :fqdn,
  :platform,
  :platform_version,
  :filesystem,
  :cpu,
  :virtualization,
  :kernel,
  :block_device,
  :user,
  :group,
].each do |key|
  file "host_inventory_#{key}" do
    owner node[:user]
    group node[:group]
    content node[key].to_s
  end
end

file 'host_inventory_cpu_total' do
  owner node[:user]
  group node[:group]
  content node[:cpu][:total]
end

# Just testing that this doesn't raise an error
file 'host_inventory_ec2' do
  owner node[:user]
  group node[:group]
  content node[:ec2][:instance_type].inspect
end
