version = "9.7p1"
url = "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-#{version}.tar.gz"

case node[:platform]
when "arch"
  raise NotImplementedError
when "osx", "darwin"
  raise NotImplementedError
when "fedora", "redhat", "amazon"
  raise NotImplementedError
when "debian", "ubuntu", "mint"
  package "openssh-client"

  execute "install openssh" do
    command <<~EOCMD
      mkdir -p work_openssh
      pushd work_openssh
      wget --no-check-certificate #{url}
      tar -zxvf openssh-#{version}.tar.gz

      cd openssh-#{version}
        ./configure
      make
      make install

      popd
    EOCMD
    not_if "ssh -V 2>&1 | grep -q 'OpenSSH_#{version}'"
  end
when "opensuse"
  raise NotImplementedError
else
  raise NotImplementedError
end
