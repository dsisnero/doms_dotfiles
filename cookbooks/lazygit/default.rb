include_recipe "dependency.rb"

github_binary "lazygit" do
  repository "jesseduffield/lazygit"
  version "v0.43.1"
  ext = ((node[:platform] == "darwin") ? "zip" : "tar.gz")
  archive "lazygit_#{version[1..-1]}_Linux_x86_64.tar.gz"
  binary_path "lazygit"
end

# target_name = "lazygit"
# version = "0.43.1"
# release_url = "https://github.com/jesseduffield/lazygit/releases/download/v#{version}/lazygit_#{version}_Linux_x86_64.tar.gz"
# version_cmd = "/usr/local/bin/#{target_name} -v"
# version_str = "Haskell Dockerfile Linter #{version}"

# case node[:platform]
# when "debian", "ubuntu", "mint", "fedora", "redhat", "amazon"
#   get_bin_github_release target_name do
#     version version
#     version_cmd version_cmd
#     version_str version_str
#     release_artifact_url release_url
#   end
# when "osx", "darwin"
# when "arch"
# when "opensuse"
# end
# version = '0.40.2'

# case node[:platform]
# when 'arch'
#   raise NotImplementedError
# when 'osx', 'darwin'
#   raise NotImplementedError
# when 'fedora', 'redhat', 'amazon'
#   raise NotImplementedError
# when 'debian', 'ubuntu', 'mint'
#   execute 'install lazygit' do
#     user node['user']

#     command <<~EOCMD
#       LAZYGIT_VERSION=#{version}
#       test -z "$LAZYGIT_VERSION" && LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r '.tag_name' | sed 's/v//' ) # version未設定だったら最新を取得する
#       curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
#       tar xf lazygit.tar.gz lazygit
#       sudo install lazygit /usr/local/bin
#       rm -f lazygit*
#     EOCMD
#   end
# when 'opensuse'
#   raise NotImplementedError
# else
#   raise NotImplementedError
# end
