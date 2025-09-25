# dotfileリポジトリ内へのシンボリックリンク設定
define :dotfile, source: nil, user: nil do
  dst = File.join(node[:config_home], params[:name])
  src = params[:source].nil? ? File.join(node[:doms_dotfiles], "config", params[:name]) : params[:source]
  user = params[:user].nil? ? node[:user] : params[:user]
  # puts "dst: #{dst}"
  # puts "src: #{src}"

  link dst do
    to src
    user user
    not_if { File.symlink? dst }
  end
end
