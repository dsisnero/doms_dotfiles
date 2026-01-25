# Test that github_binary plugin loads correctly
github_binary "test-plugin-load" do
  repo "jqlang/jq"
  version "jq-1.7"
  binary_name "jq"
  install_path "/tmp/test-jq"
  only_if "false"  # Don't actually download, just test plugin loading
end

execute "echo plugin loaded" do
  command "echo 'github_binary plugin loaded successfully'"
end
