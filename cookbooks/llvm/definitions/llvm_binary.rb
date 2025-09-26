define :llvm_binary, name: nil do
  binary_name = params[:name]
  config_dir = node[:config_dir]
  link_path = "#{config_dir}/.local/bin/#{binary_name}"

  source_path = if node[:platform] == "darwin"
    "$(brew --prefix llvm)/bin/#{binary_name}"
  else
    "/usr/bin/#{binary_name}"
  end

  not_if_str = if node[:platform] == "darwin"
    "test -L #{link_path} && test \\\"$(readlink #{link_path})\\\" = \\\"$(brew --prefix llvm)/bin/#{binary_name}\\\""
  else
    "test -L #{link_path} && test \\\"$(readlink #{link_path})\\\" = \\\"/usr/bin/#{binary_name}\\\""
  end

  execute "link #{binary_name} to #{link_path}" do
    command "ln -sf #{source_path} #{link_path}"
    user node[:user]
    not_if not_if_str
  end
end
