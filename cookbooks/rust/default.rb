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
rustup = "#{cargo_bin_dir}/rustup"
cargo_cmd = "#{cargo_bin_dir}/cargo"

cargo_env = <<~EOS
  export PATH=#{cargo_bin_dir}:$PATH
EOS

unless ENV["PATH"].include?(cargo_bin_dir)
  MItamae.logger.info("Prepending ~/.cargo/bin to PATH during this execution ")
  ENV["PATH"] = "#{cargo_bin_dir}:#{ENV["PATH"]}"
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

cargo_init = <<~EOS
  ENV['RUSTC_WRAPPER'] = "#{cargo_bin_dir}/sccache"
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

file "#{home}/.bashrc" do
  action :edit
  not_if "grep 'source $HOME/.cargo/env' #{home}/.bashrc"
  block do |content|
    content << "source $HOME/.cargo/env"
  end
end

file "#{home}/.bashrc" do
  action :edit
  not_if "grep 'zoxide init bash' #{home}/.bashrc"
  block do |content|
    content << %(eval "$(zoxide init bash)")
  end
end

file "#{home}/.bashrc" do
  action :edit
  not_if "grep 'export RUSTC_WRAPPER' #{home}/.bashrc"
  block do |content|
    content << %(export RUSTC_WRAPPER=#{cargo_bin_dir}/.sccache)
  end
end
file "#{home}/.zshrc" do
  action :edit
  not_if "grep 'source $HOME/.cargo/env' #{home}/.zshrc"
  block do |content|
    content << "source $HOME/.cargo/env"
  end
end

file "#{home}/.zshrc" do
  action :edit
  not_if "grep 'export RUSTC_WRAPPER' #{home}/.zshrc"
  block do |content|
    content << %(export RUSTC_WRAPPER=#{cargo_bin_dir}/.sccache)
  end
end
