# dotfileリポジトリ内へのシンボリックリンク設定
define :dotfile, source: nil, user: nil do
  dst = File.join(node[:config_home], params[:name])
  src = params[:source].nil? ? File.join(node[:doms_dotfiles], "config", params[:name]) : params[:source]
  user = params[:user].nil? ? node[:user] : params[:user]

  execute "remove existing file/directory before symlink #{dst}" do
    command "rm -rf #{dst}"
    user user
    only_if { File.exist?(dst) && !File.symlink?(dst) }
  end

  link dst do
    to src
    user user
    not_if { File.symlink? dst }
  end
end
