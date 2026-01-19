include_cookbook "mise"

mise "opencode"

# include_recipe "./dependency.rb"

# user = node[:user]
# home = node[:home]
# install_dir = "#{home}/.opencode/bin"

# mydir install_dir

# # Determine OS
# os = case node[:platform]
# when "debian", "ubuntu", "mint", "fedora", "redhat", "amazon", "arch", "opensuse"
#   "linux"
# when "darwin", "osx"
#   "darwin"
# when "windows"
#   "windows"
# else
#   "linux" # default
# end

# # Determine architecture
# arch = node[:kernel][:machine]
# case arch
# when "aarch64"
#   arch = "arm64"
# when "x86_64"
#   arch = "x64"
# end

# # Handle macOS Rosetta detection
# if os == "darwin" && arch == "x64"
#   result = run_command("sysctl -n sysctl.proc_translated 2>/dev/null || echo 0", error: false)
#   if result.stdout.strip == "1"
#     arch = "arm64"
#   end
# end

# # Check for musl (Linux only)
# is_musl = false
# if os == "linux"
#   # Check /etc/alpine-release
#   if File.exist?("/etc/alpine-release")
#     is_musl = true
#   end

#   # Check ldd
#   result = run_command("ldd --version 2>&1 || echo ''", error: false)
#   if result.stdout.downcase.include?("musl")
#     is_musl = true
#   end
# end

# # Check for baseline CPU (no AVX2)
# needs_baseline = false
# if arch == "x64"
#   if os == "linux"
#     result = run_command("grep -qi avx2 /proc/cpuinfo 2>/dev/null || echo ''", error: false)
#     needs_baseline = !result.success?
#   elsif os == "darwin"
#     result = run_command("sysctl -n hw.optional.avx2_0 2>/dev/null || echo 0", error: false)
#     needs_baseline = result.stdout.strip != "1"
#   end
# end

# # Build target string
# target = "#{os}-#{arch}"
# if needs_baseline
#   target = "#{target}-baseline"
# end
# if is_musl
#   "#{target}-musl"
# end

# # Get latest version
# version = github_latest_version("anomalyco/opencode") || "latest"

# # Archive extension
# archive_ext = (os == "linux") ? ".tar.gz" : ".zip"
# filename = "opencode-#{target}#{archive_ext}"

# # Download URL
# url = "https://github.com/anomalyco/opencode/releases/download/v#{version}/#{filename}"

# # Temporary directory
# tmp_dir = "/tmp/opencode_install_#{Process.pid}"
# directory tmp_dir do
#   action :create
#   owner user
# end

# # Download the archive
# downloaded_file = "#{tmp_dir}/#{filename}"
# http_request "download opencode #{version}" do
#   url url
#   path downloaded_file
#   owner user
#   not_if "test -f #{install_dir}/opencode"
#   notifies :run, "execute[extract opencode]", :immediately
# end

# # Extract based on archive type
# if os == "linux"
#   execute "extract opencode" do
#     action :nothing
#     command "tar -xzf #{downloaded_file} -C #{tmp_dir}"
#     cwd tmp_dir
#     user user
#     notifies :run, "execute[install opencode]", :immediately
#   end
# else
#   execute "extract opencode" do
#     action :nothing
#     command "unzip -q #{downloaded_file} -d #{tmp_dir}"
#     cwd tmp_dir
#     user user
#     notifies :run, "execute[install opencode]", :immediately
#   end
# end

# # Install binary
# execute "install opencode" do
#   action :nothing
#   command "mv #{tmp_dir}/opencode #{install_dir}/ && chmod 755 #{install_dir}/opencode"
#   user user
# end

# # Cleanup (run after install)
# directory tmp_dir do
#   action :delete
#   only_if { File.exist?(tmp_dir) }
# end

# # Add to PATH in shell configs (skip on Windows)
# unless windows?
#   zshrc_config = node[:zshrc_config]

#   # Add to .bashrc
#   execute "Add opencode to #{home}/.bashrc" do
#     user user
#     command %(
#       if ! grep -q 'export PATH=.*#{install_dir}' #{home}/.bashrc; then
#         echo 'export PATH=#{install_dir}:$PATH' >> #{home}/.bashrc
#       fi
#     )
#   end

#   # Add to zshrc config (dotfiles)
#   execute "Add opencode to #{zshrc_config}" do
#     user user
#     command %(
#       if ! grep -q 'export PATH=.*#{install_dir}' #{zshrc_config}; then
#         echo 'export PATH=#{install_dir}:$PATH' >> #{zshrc_config}
#       fi
#     )
#   end
# end
