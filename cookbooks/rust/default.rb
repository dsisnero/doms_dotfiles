# include_recipe './dependency.rb'
# include_cookbook './asdf

node.reverse_merge!({
  rust: {
    version: 'stable',
    user: node[:user]
  }
})

include_recipe "rust::user"

unless ENV["PATH"].include?("#{node[:home]}/.cargo/bin:")
  MItamae.logger.info("Prepending ~/.cargo/bin to PATH during this execution")
  ENV["PATH"] = "#{node[:home]}/.cargo/bin:#{ENV["PATH"]}"
end

rustup = "#{node[:home]}/.cargo/bin/rustup"
cargo_cmd = "#{node[:home]}/.cargo/bin/cargo"

# execute "sudo -E -u #{node[:user]} #{rustup} component add rust-src" do
#   not_if "sudo -E -u #{node[:user]} #{rustup} component list | grep 'rust-src (installed)' >/dev/null"
# end

# add RUSTC_WRAPPER to ENV
unless ENV["RUSTC_WRAPPER"]
  MItamae.logger.info("adding RUSTC_WRAPPER to ENV during this execution")
  ENV["RUSTC_WRAPPER"] = "#{node[:home]}/.cargo/bin/sccache"
end

cargo_init = <<~EOS
  ENV['RUSTC_WRAPPER'] = "#{node[:home]}/.cargo/bin/sccache"
EOS

# define cargo_install command
define :cargo, version: nil, locked: true, path: nil, git: nil,
  features: nil, binname: nil, sscache: true do
    cargo_name = params[:name]
    binname = params[:binname] || params[:name]
    cmd = "#{cargo_init} ;" if params[:sscache]
    cmd = "#{cargo_cmd} install --verbose"
    cmd << " --version #{params[:version]}" if params[:version]
    cmd << " --path #{params[:path]}" if params[:path]
    cmd << " --git #{params[:git]}" if params[:git]
    cmd << " --features #{params[:features]}" if params[:features]
    cmd << " --locked" if params[:locked]
    cmd << " #{cargo_name}" unless params[:path] || params[:git]
    execute "installing_cmd" do
      user node[:user]
      command cmd
      not_if %(#{cargo_cmd} install --list | grep "^#{cargo_name} ")
    end
  end

# add RUSTC_WRAPPER to .bashrc
execute "add RUSTC_WRAPPER to .bashrc" do
  command "echo 'export RUSTC_WRAPPER=#{ENV["HOME"]}/.cargo/bin/sccache' >> #{ENV["HOME"]}/.bashrc"
  command "source #{ENV["HOME"]}/.bashrc"
  not_if "grep 'export RUSTC_WRAPPER' #{ENV["HOME"]}/.bashrc"
end

# # install helix
# git "helix" do
#   repository "https://github.com/helix-editor/helix"
#   destination "#{ENV["HOME"]}/src/helix"
#   user node[:user]
#   revision "HEAD"
# end
#
# execute "helix compile" do
#   cwd "#{ENV["HOME"]}/src/helix"
#   user node[:user]
#   command "#{cargo_cmd} install --path helix-term --locked"
#   not_if "which hx"
# end
#
# # add HELIX_RUNTIME to .bashrc
# execute "add HELIX_RUNTIME to .bashrc" do
#   command "echo 'export HELIX_RUNTIME=#{ENV["HOME"]}/src/helix/runtime' >> #{ENV["HOME"]}/.bashrc"
#   not_if "grep 'export HELIX_RUNTIME' #{ENV["HOME"]}/.bashrc"
# end
