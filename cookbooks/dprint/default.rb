include_cookbook "mise"

mise "dprint"
doms_dotfiles = node[:doms_dotfiles]
src = File.join(doms_dotfiles, "config", "dprint_config.json")
dotfile "dprint/config.json" do
  source src
end
