# include_recipe 'dependency.rb'
include_cookbook "ghq"
  get_repo "estin/simple-completion-language-server" do
    build <<-EOCMD
    mise exec -- ./cargo install --path .
    EOCMD
  end
