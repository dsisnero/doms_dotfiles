# インストールスクリプトのダウンロード
execute "wget -O /tmp/starship-install.sh https://starship.rs/install.sh" do
  not_if "test -e /usr/local/bin/starship"
end

execute "chmod +x /tmp/starship-install.sh" do
  not_if "test -e /usr/local/bin/starship"
end

execute "/tmp/starship-install.sh -y" do
  user "root"

  not_if "test -e /usr/local/bin/starship"
end
