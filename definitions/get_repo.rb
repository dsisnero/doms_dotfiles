define :get_repo, build: nil do
  reponame = params[:name]
  user = params[:user].nil? ? ENV["SUDO_USER"] || ENV["USER"] : node[:user]
  home = node[:home]

  # Parse repository URL format
  repo_url = if reponame.include?("://") || reponame.include?("@")
    reponame # Already a full URL
  else
    "https://github.com/#{reponame}.git"
  end

  # Extract proper ghq path from URL
  cloned_dir = "#{node[:repos]}/#{repo_url.split(%r{[:/]})[1..-1].join("/").gsub(/\.git$/, "")}"

  execute "get_repo #{reponame}" do
    command "SSH_AUTH_SOCK=#{home}/.ssh/agent.sock mise exec -- ghq get -p '#{repo_url}'"
    user user
    not_if { File.directory? cloned_dir }
  end

  unless params[:build].nil?
    version_check = if params[:version_cmd] && params[:version_str]
      " && #{params[:version_cmd]} | grep -q '#{params[:version_str]}'"
    else
      ""
    end

    execute "build #{reponame}" do
      command "cd #{cloned_dir} && #{params[:build]}"
      user user
      not_if { File.directory? "#{cloned_dir}/target#{version_check}" }
    end
  end
end
