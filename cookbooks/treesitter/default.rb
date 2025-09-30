case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  package "libtree-sitter-dev"
when "darwin"
  package "tree-sitter"
  package "tree-sitter-cli"
end

mydir "#{node[:config_home]}/tree-sitter"
