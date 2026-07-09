include_recipe "dependency.rb"

# docker_compose_version = '2.6.0'

# home = node[:home]
user = node[:user]
group = node[:group]

case node[:platform]
when "debian", "mint"
  # not implemented
when "ubuntu"
  execute "update-alternatives --set iptables /usr/sbin/iptables-legacy" if node[:is_wsl]

  url = "https://download.docker.com/linux/ubuntu"
  execute "add docker repo" do
    command <<~EOCMD
      curl -fsSL #{url}/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] #{url} $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt-get update -y
    EOCMD
    not_if "test -f /etc/apt/sources.list.d/docker.list"
  end

  # install docker
  %w[
    apt-transport-https
    ca-certificates
    curl
    gnupg
    lsb-release
    docker-ce
    docker-ce-cli
    containerd.io
    docker-compose-plugin
  ].each { |pkgname| package pkgname }
when "fedora", "redhat", "amazon"
  # https://matsuand.github.io/docs.docker.jp.onthefly/engine/security/rootless/

when "osx", "darwin"
  execute "install Docker Desktop" do
    command "brew install --cask docker"
    not_if "brew list --cask docker >/dev/null 2>&1 || test -d /Applications/Docker.app"
  end
when "arch"
  # yay 'docker'
  # https://matsuand.github.io/docs.docker.jp.onthefly/engine/security/rootless/

  yay "docker-compose"
when "opensuse"
  # not implemented
else
  # not implemented
end

case node[:platform]
when "debian", "ubuntu", "mint", "fedora", "redhat", "amazon", "arch", "opensuse"
  execute "usermod -G #{group},docker #{user}" do
    not_if "id -nG #{user} | tr ' ' '\\n' | grep -qx docker"
  end

  service "docker" do
    action %i[enable start]
  end
else
  MItamae.logger.info "Skipping docker group/service setup on #{node[:platform]} (use Docker Desktop)"
end

execute "update docker's zsh completions." do
  command "mkdir -p #{node[:doms_dotfiles]}/config/zsh/functions/completions && curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > #{node[:doms_dotfiles]}/config/zsh/functions/completions/_docker"
  not_if { File.exist?("#{node[:doms_dotfiles]}/config/zsh/functions/completions/_docker") }
end
