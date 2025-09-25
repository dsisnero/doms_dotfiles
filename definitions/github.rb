define :github_binary, version: nil, repository: nil, archive: nil,
  binary_path: nil, version_cmd: nil, version_str: nil do
  cmd = params[:name]
  bin_path = "#{node[:user_bin]}/#{cmd}"
  params[:binary_path]
  archive = params[:archive]
  params[:version_cmd]
  params[:version_str]
  user = node[:user]
  test_cmd = "test -f #{bin_path}"
  # add version test test_cmd
  url = "https://github.com/#{params[:repository]}/releases/download/#{params[:version]}/#{archive}"

  if archive.end_with?(".zip")
    package "unzip" do
      not_if "which unzip"
    end
    extract = "unzip -o"
  elsif archive.end_with?(".tar.gz")
    extract = "tar xvzf"
  elsif archive.end_with?(".appimage")
    extract = "ls "
    params[:binary_path] = archive
    url = "https://github.com/#{params[:repository]}/releases/latest/download/#{archive}"
  else
    raise "unexpected ext archive: #{archive}"
  end

  directory node[:user_bin] do
    owner node[:user]
  end

  execute "curl -fSL -o /tmp/#{archive} #{url}" do
    not_if "test -f #{bin_path}"
  end

  execute "#{extract} /tmp/#{archive}" do
    not_if "test -f #{bin_path}"
    cwd "/tmp"
  end
  execute "mv /tmp/#{params[:binary_path] || cmd} #{bin_path} && chmod +x #{bin_path} && chown #{user}:#{user} #{bin_path}" do
    not_if test_cmd.to_s
  end
end

define :get_bin_github_release, version: nil, version_cmd: nil, version_str: nil, release_artifact_url: nil do
  target_name = params[:name]
  params[:version]

  version = params[:version]
  version_cmd = params[:version_cmd]
  version_str = params[:version_str]
  release_url = params[:release_artifact_url]

  execute "install #{target_name}" do
    command <<-EOCMD
    WORKDIR=work_#{version}

    cur=$(pwd) mkdir -p ${WORKDIR} cd ${WORKDIR} wget #{release_url} -O #{target_name} install #{target_name} /usr/local/bin/#{target_name} cd ${cur}
    rm -rf ${WORKDIR}
    EOCMD

    not_if "test -e /usr/local/bin/#{target_name} && test \"$(#{version_cmd})\" = \"#{version_str}\""
  end
end
