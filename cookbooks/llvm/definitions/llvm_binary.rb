define :llvm_binary, name: nil do
  binary_name = params[:name]
  source_name = params[:source] || binary_name
  user_bin = node[:user_bin] || File.join(node[:home], ".local", "bin")
  link_path = File.join(user_bin, binary_name)

  source_path = if node[:platform] == "darwin" || node[:platform] == "osx"
    "$(brew --prefix llvm)/bin/#{source_name}"
  else
    "/usr/bin/#{source_name}"
  end

  directory user_bin do
    owner node[:user]
    group node[:group] || node[:user]
    mode "755"
  end

  not_if_str = if node[:platform] == "darwin" || node[:platform] == "osx"
    "test -L '#{link_path}' && test \"$(readlink '#{link_path}')\" = \"#{source_path}\""
  else
    "test -L '#{link_path}' && test \"$(readlink '#{link_path}')\" = '#{source_path}'"
  end

  execute "link #{binary_name} to #{link_path}" do
    command "ln -sfn \"#{source_path}\" '#{link_path}'"
    user node[:user]
    only_if "test -x \"#{source_path}\""
    not_if not_if_str
  end
end
