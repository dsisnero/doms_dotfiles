# include_recipe './dependency.rb'
# include_cookbook './asdf

node.reverse_merge!({
  rust: {
    version: "stable",
    user: node[:user]
  }
})

include_recipe "rust::user"
user = node[:user]
home = node[:home]

cargo_home = node[:rust][:cargo_home]
cargo_bin_dir = "#{cargo_home}/bin"
cargo_cmd = "#{cargo_bin_dir}/cargo"

cargo_env = <<~EOS
  export PATH=#{cargo_bin_dir}:$PATH
EOS

unless ENV["PATH"].include?(cargo_bin_dir)
  MItamae.logger.info("Prepending ~/.cargo/bin to PATH during this execution ")
  ENV["PATH"] = "#{cargo_bin_dir}:#{ENV["PATH"]}"
end

execute "install sccache" do
  user user
  command "#{cargo_env} cargo install sccache --locked"
  not_if { File.exist? "#{cargo_bin_dir}/sccache" }
end

# execute "install rust-src" do
#   user user
#   not_if do
#     puts "ENV path for rustup: #{ENV["PATH"]}"
#     `rustup component list | grep installed`.split("\n").any? { _1 =~ /rust-src/ }
#   end
#   command "#{cargo_env} ; rustup component add rust-src"
# end

# execute "sudo -E -u #{node[:user]} #{rustup} component add rust-src" do
#   not_if "sudo -E -u #{node[:user]} #{rustup} component list | grep 'rust-src (installed)' >/dev/null"
# end

# add RUSTC_WRAPPER to ENV
unless ENV["RUSTC_WRAPPER"]
  MItamae.logger.info("adding RUSTC_WRAPPER to ENV during this execution")
  ENV["RUSTC_WRAPPER"] = "#{cargo_bin_dir}/sccache"
end
ENV["RUSTC_WRAPPER"] = "#{cargo_bin_dir}/sccache"

# define cargo_install command
define :cargo, version: nil, locked: true, path: nil, git: nil,
  features: nil, binname: nil, sscache: true, env: {}, cwd: nil, user: nil do
    cargo_name = params[:name]
    params[:binname] || params[:name]
    target_user = params[:user] || node[:user]

    # Build environment exports
    env_exports = []
    # Add BEADS_DIR if beads is installed
    if system("which bd > /dev/null 2>&1")
      beads_dir = "#{node[:doms_dotfiles]}/.beads"
      FileUtils.mkdir_p(beads_dir) unless File.exist?(beads_dir)
      env_exports << "BEADS_DIR=#{beads_dir}"
    end
    # Add user-provided environment variables
    params[:env].each do |key, value|
      env_exports << "#{key}=#{value}"
    end

    # Build cargo command
    cmd = "#{cargo_cmd} install --verbose"
    cmd << " --version #{params[:version]}" if params[:version]
    cmd << " --path #{params[:path]}" if params[:path]
    cmd << " --git #{params[:git]}" if params[:git]
    cmd << " --features #{params[:features]}" if params[:features]
    cmd << " --locked" if params[:locked]
    cmd << " #{cargo_name}" unless params[:path] || params[:git]

    # Prepend environment exports if any
    if !env_exports.empty?
      cmd = env_exports.map { |e| "export #{e}" }.join(" && ") + " && " + cmd
    end

    # Change directory if cwd specified
    if params[:cwd]
      cmd = "cd #{params[:cwd]} && " + cmd
    end

    execute "installing #{cargo_name}" do
      user target_user
      command cmd
      not_if %(#{cargo_cmd} install --list | grep "^#{cargo_name} ")
    end
  end

file "#{home}/.bashrc" do
  action :edit
  not_if "grep 'source $HOME/.cargo/env' #{home}/.bashrc"
  content "source $HOME/.cargo/env"
end

file "#{home}/.bashrc" do
  action :edit
  not_if "grep 'export RUSTC_WRAPPER' #{home}/.bashrc"
  content %(export RUSTC_WRAPPER=#{cargo_bin_dir}/sccache)
end
file "#{home}/.zshrc" do
  action :edit
  not_if "grep 'source $HOME/.cargo/env' #{home}/.zshrc"
  content "source $HOME/.cargo/env"
end

file "#{home}/.zshrc" do
  action :edit
  not_if "grep 'export RUSTC_WRAPPER' #{home}/.zshrc"
  content %(export RUSTC_WRAPPER=#{cargo_bin_dir}/sccache)
end
