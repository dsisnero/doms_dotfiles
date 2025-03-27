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
get_repo "github.com/estin/simple-completion-language-server",
  repository: "estin/simple-completion-language-server",
  build: <<-EOCMD
    cd #{home}/repos/github.com/estin/simple-completion-language-server
    cargo install --path .
  EOCMD
  version_cmd: "simple-completion-language-server --version",
  version_str: "0.1.0"
)
