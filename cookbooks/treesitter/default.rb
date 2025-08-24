cargo "tree-sitter-cli"
case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  package "libtree-sitter-dev"
when "osx"
  package "treesitter"
end
