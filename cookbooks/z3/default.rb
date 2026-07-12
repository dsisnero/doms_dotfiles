case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  package "z3"
when "darwin", "osx"
  package "z3"
when "fedora", "redhat", "amazon"
  package "z3"
when "arch"
  package "z3"
when "opensuse"
  package "z3"
when "windows"
  chocolatey_package "z3"
end
