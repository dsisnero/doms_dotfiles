# include_recipe 'dependency.rb'

case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  get_repo "estin/simple-completion-language-server" do
    build <<-EOCMD
    mise exec -- ./cargo install --path .
    EOCMD
  end
when "fedora", "redhat", "amazon"
  get_repo "etsin/simple-completion-language-server" do
    build <<-EOCMD
    mise exec -- ./cargo install --path .
    EOCMD
  end
when "osx", "darwin"
  package "migemo"
when "arch"
  package "migemo"
when "opensuse"
  # nothing to do
when "windows"
  get_repo "etsin/simple-completion-language-server" do
    build <<-EOCMD
    mise exec -- ./cargo install --path .
    EOCMD
  end
end
