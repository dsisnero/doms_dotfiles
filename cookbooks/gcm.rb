package libsecret - 1 - 0
packafe libsecret - 1 - dev

user = node[:user]
home = node[:home]
gcm_version = "2.0.935"
gcm_url = "https://github.com/GitCredentialManager/git-credential-manager/releases/download/v#{gcm_version}/gcm-linux_amd64.#{gcm_version}.tar.gz"
gcm_tar = "#{home}/gcm-linux_amd64.#{gcm_version}.tar.gz"
gcm_dir = "#{home}/gcm"

# Ensure pass is installed
package "pass"

# Download Git Credential Manager
http_request "download gcm" do
  url gcm_url
  path gcm_tar
  owner user
  not_if { ::File.exist?(gcm_tar) }
end

# Extract and install GCM
execute "install gcm" do
  command "mkdir -p #{gcm_dir} && tar -xzf #{gcm_tar} -C #{gcm_dir} && #{gcm_dir}/install.sh"
  user user
  not_if { ::File.exist?("#{gcm_dir}/git-credential-manager") }
end

# Configure GCM to use pass
execute "configure gcm with pass" do
  command "git-credential-manager configure --credentialStore pass"
  user user
end
