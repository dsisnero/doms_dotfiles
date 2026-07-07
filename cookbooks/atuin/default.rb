include_cookbook "mise"

mise "atuin"

completions_dir = "#{node[:doms_dotfiles]}/config/zsh/functions/completions"

execute "generate atuin zsh completions" do
  command "atuin gen-completions -s zsh > #{completions_dir}/_atuin"
  not_if "test -f #{completions_dir}/_atuin"
end
