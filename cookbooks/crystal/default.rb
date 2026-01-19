include_recipe "dependency.rb"
case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  execute "curl -fsSL https://crystal-lang.org/install.sh | sudo bash " do
    not_if "crystal --version"
  end
when "osx", "darwin"
  package "crystal"
end

# Download Crystal LLDB formatters
doms_dotfiles = node[:doms_dotfiles]
config_home = node[:config_home]
user_bin = node[:user_bin]
# Create directories
mydir "#{doms_dotfiles}/config/lldb"
mydir "#{config_home}/lldb"

# Download the crystal formatters file
execute "download crystal_formatters.py" do
  command "curl -fsSL -o '#{doms_dotfiles}/config/lldb/crystal_formatters.py' 'https://raw.githubusercontent.com/crystal-lang/crystal/refs/heads/master/etc/lldb/crystal_formatters.py'"
  user node[:user]
  not_if "test -f '#{doms_dotfiles}/config/lldb/crystal_formatters.py'"
end

# Create link to config home
link "#{config_home}/lldb/crystal_formatters.py" do
  to "#{doms_dotfiles}/config/lldb/crystal_formatters.py"
  user node[:user]
end

# crystalline
# get_repo("elbywan/crystalline") do
#     build <<-EOCMD
#     EOCMD
# end
get_repo("elbywan/crystalline")
# #
# # Define the Crystal version and channel
# crystal_version = ENV["CRYSTAL_VERSION"] || "latest"
# channel = ENV["CHANNEL"] || "stable"
# os_release = File.read("/etc/os-release")
# id = os_release.match(/^ID=(.*)$/)[1]
# version_id = os_release.match(/^VERSION_ID=(.*)$/)[1]
#
# # Determine the distribution repository
# distro_repo = case id
# when "debian"
#   version_id = "Unstable" if version_id.empty?
#   "Debian_#{version_id}"
# when "ubuntu", "pop", "mint"
#   "xUbuntu_#{version_id}"
# when "fedora"
#   version_id.include?("Prerelease") ? "Fedora_Rawhide" : "Fedora_#{version_id}"
# when "centos"
#   "CentOS_#{version_id}"
# when "rhel"
#   "RHEL_#{version_id}"
# when "opensuse-tumbleweed"
#   "openSUSE_Tumbleweed"
# when "opensuse-leap"
#   version_id
# else
#   ""
#   # raise "Unsupported distribution: #{id}"
# end
#
# # Install Crystal based on the package manager
# case node[:platform]
# when "debian", "ubuntu", "mint"
#   package "wget"
#   package "gpg"
#
#   execute "add crystal repo key" do
#     command "wget -qO- https://download.opensuse.org/repositories/devel:languages:crystal/#{distro_repo}/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/devel_languages_crystal.gpg > /dev/null"
#   end
#
#   file "/etc/apt/sources.list.d/crystal.list" do
#     content "deb http://download.opensuse.org/repositories/devel:languages:crystal/#{distro_repo}/ /"
#   end
#
#   execute "apt update" do
#     command "apt-get update"
#   end
#
#   package "crystal" do
#     version crystal_version unless crystal_version == "latest"
#   end
#
# when "fedora", "redhat", "amazon"
#   execute "import crystal repo key" do
#     command "rpm --verbose --import https://build.opensuse.org/projects/devel:languages:crystal/signing_keys/download?kind=gpg"
#   end
#
#   file "/etc/yum.repos.d/crystal.repo" do
#     content <<~EOF
#       [crystal]
#       name=Crystal (#{distro_repo})
#       type=rpm-md
#       baseurl=https://download.opensuse.org/repositories/devel:languages:crystal/#{distro_repo}/
#       gpgcheck=1
#       gpgkey=https://download.opensuse.org/repositories/devel:languages:crystal/#{distro_repo}/repodata/repomd.xml.key
#       enabled=1
#     EOF
#   end
#
#   package "crystal" do
#     version crystal_version unless crystal_version == "latest"
#   end
#
# when "opensuse"
#   package "curl"
#
#   execute "import crystal repo key" do
#     command "rpm --verbose --import https://build.opensuse.org/projects/devel:languages:crystal/signing_keys/download?kind=gpg"
#   end
#
#   execute "add crystal repo" do
#     command "zypper --non-interactive addrepo https://download.opensuse.org/repositories/devel:languages:crystal/#{distro_repo}/devel_languages_crystal.repo"
#   end
#
#   execute "refresh zypper" do
#     command "zypper --non-interactive refresh"
#   end
#
#   package "crystal" do
#     version crystal_version unless crystal_version == "latest"
#   end
#
# else
#   # not implemented
# end
