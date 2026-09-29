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

include_recipe File.join(File.dirname(__FILE__), "definitions", "llvm_binary.rb")

# Crystal's compiler locates LLVM through this executable.  Homebrew keeps it
# in LLVM's keg-only bin directory, so make it available in the user bin path.
llvm_binary "llvm-config"

# Homebrew intentionally does not provide an `llvm` command.  Expose its
# version/configuration tool under that conventional name so `which llvm` and
# `llvm --version` work consistently across supported platforms.
llvm_binary "llvm" do
  source "llvm-config"
end

llvm_binary "lldb-dap"
