node[:user]

case node[:platform]
when "darwin"
  package "llvm"
when "ubuntu"
  package "llvm"
  package "llvm-dev"
when "arch"
  package "llvm"
end

# Create lldb config directory
node[:doms_dotfiles]
node[:config_home]
define :llvm_binary, name: nil do
  binary_name = params[:name]
  user_bin = node[:user_bin]
  link_path = File.join(user_bin, binary_name)
  llvm_prefix = nil

  local_ruby_block "capture brew prefix" do
    block do
      result = run_command("brew --prefix llvm", error: false)
      if result.exit_status == 0 && !result.stdout.strip.empty?
        llvm_prefix = result.stdout.strip
        # Only update and notify if the value is new or different
        if node[:llvm_prefix] != llvm_prefix
          node[:llvm_prefix] = llvm_prefix
          MItamae.logger.info "Set llvm_prefix to #{llvm_prefix}"
        end
      else
        node[:llvm_prefix] = nil
      end
    end
    # Trigger the 'create_link' block by its unique name
    notifies :run, "local_ruby_block[create_llvm_link_#{binary_name}]", :immediately
  end

  local_ruby_block "create_llvm_link_#{binary_name}" do
    action :nothing
    block do
      if node[:llvm_prefix]
        source_path = File.join(node[:llvm_prefix], "bin", binary_name)
        run_command("mkdir -p #{File.dirname(link_path)}")
        run_command("ln -sf #{source_path} #{link_path}")
        MItamae.logger.info "Linked #{source_path} → #{link_path}"
      else
        MItamae.logger.warn "Skipping link creation: llvm_prefix not set"
      end
    end
  end
end
llvm_binary "lldb-dap"
