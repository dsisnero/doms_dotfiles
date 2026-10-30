include_cookbook "ghq"
include_cookbook "rust"
ghq_root = node[:ghq_root]
config_home = node[:config_home]
node[:user]
home = node[:home]
doms_dotfiles = node[:doms_dotfiles]
config_dir = node[:config_home]
node[:zshrc_config]

# mise "helix" do
#   exe "hx"
# end

dest = "#{config_dir}/helix/snippets"
src = "#{doms_dotfiles}/config/helix/snippets"

link dest do
  to src
  user node[:user]
  not_if { File.directory? dest }
end

# # Special handling for snippets directory
# execute "symlink helix snippets" do
#   command "ln -sfT #{doms_dotfiles}/config/helix/snippets #{config_dir}/helix/snippets"
#   user user
#   only_if {File.directory? "#{doms_dotfiles}/config/helix/snippets" }
#   not_if "test -L #{config_dir}/helix/snippets"
# end

# Raspberry Pi specific packages (if running on ARM architecture)
if rasppi?
  mise "helix"
else
  get_repo("helix-editor/helix")

  dir = File.join(ghq_root, "github.com/helix-editor/helix")
  cargo "helix-locked" do
    path "#{dir}/helix-term"
    cwd dir
  end

  src = File.expand_path(File.join(dir, "runtime"))
  dest = "#{config_home}/helix/runtime"
  link dest do
    to src
    user node[:user]
    not_if { File.directory? dest }
  end

end

# --- grammars ---------------------------------------------------------------
# `hx --grammar fetch|build` only installs what is declared under [[grammar]]
# in the *merged* languages.toml (built-in defaults + the user file written by
# cookbooks/dotfiles). Grammars are written to runtime_dirs().first(), which is
# always <config>/helix/runtime, i.e. the link above -> the helix checkout.
# Crystal has no upstream grammar, so it is declared by hand in
# cookbooks/dotfiles/templates/helix/languages.toml.erb; without the fetch/build
# below, `.cr` files silently lose highlighting on a fresh machine.
helix_languages = File.join(config_home, "helix", "languages.toml")
grammar_root = File.join(config_home, "helix", "runtime", "grammars")
crystal_source = File.join(grammar_root, "sources", "crystal")
crystal_parser = File.join(crystal_source, "src", "parser.c")
crystal_lib = File.join(grammar_root, "crystal.#{windows? ? "dll" : "so"}")

# pinned rev of the crystal grammar as rendered into languages.toml
crystal_rev = ""
if File.exist?(helix_languages)
  File.read(helix_languages).each_line do |line|
    next unless line.include?("tree-sitter-crystal")

    match = line.match(/rev = "([0-9a-f]+)"/)
    crystal_rev = match[1] if match
  end
end

rust_cargo_home = (node[:rust] || {})[:cargo_home].to_s
hx_candidates = [
  File.join(rust_cargo_home, "bin", "hx"),               # cargo build below
  File.join(home, ".local", "bin", "hx"),                # mise shims / manual
  File.join(home, ".local", "share", "mise", "shims", "hx")
]
hx_cmd = hx_candidates.find { |candidate| File.exist?(candidate) } || ""

if hx_cmd.empty?
  MItamae.logger.warn "helix: hx not found in #{hx_candidates.inspect}, skipping grammar install"
else
  crystal_source_pinned = if crystal_rev.empty? || !File.directory?(crystal_source)
    false
  else
    run_command("git -C #{crystal_source} rev-parse HEAD", error: false).stdout.strip == crystal_rev
  end

  # mruby has no File.mtime, but File.stat(path).mtime works
  crystal_lib_current = if File.exist?(crystal_lib) && File.exist?(crystal_parser)
    File.stat(crystal_lib).mtime >= File.stat(crystal_parser).mtime
  else
    false
  end

  # fetch is all-or-nothing: it clones every grammar in the merged config, so
  # it only runs when the pinned crystal rev is not checked out (first install
  # or after a rev bump in the template).
  execute "helix fetch grammars" do
    command "#{hx_cmd} --grammar fetch"
    user node[:user]
    not_if { crystal_source_pinned }
  end

  # build is incremental (helix compares parser.c/scanner.c mtimes) but still
  # sweeps every grammar, so skip it when crystal's library is already newer
  # than its sources.
  execute "helix build grammars" do
    command "#{hx_cmd} --grammar build"
    user node[:user]
    only_if { File.exist?(crystal_parser) }
    not_if { crystal_lib_current }
  end
end

# share_dir = "#{home}/.local/share"

# mydir share_dir
# mydir "#{share_dir}/icons"
# mydir "#{share_dir}/applications"
# # copy the desktop icons
# execute "copy helix desktop icons" do
#   user user
#   command <<~EOS
#       cp #{dir}/contrib/Helix.desktop #{share_dir}/applications
#     cp #{dir}/contrib/helix.png  #{share_dir}/icons
#   EOS
# end

# change_links_cmd = <<~EOS
#   sed -i -e "s|Exec=hx %F|Exec=$(readlink -f ~/.cargo/bin/hx) %F|g" \
#     -e "s|Icon=helix|Icon=$(readlink -f #{share_dir}/icons/helix.png)|g" #{share_dir}/applications/Helix.desktop
# EOS

# execute "change links in helix .desktop file to absolute paths" do
#   user user
#   command change_links_cmd
# end

# # add HELIX_RUNTIME to .bashrc
# execute "add HELIX_RUNTIME to .bashrc" do
#   command "echo 'export HELIX_RUNTIME=#{dir}/runtime' >> #{home}/.bashrc"
#   not_if "grep 'export HELIX_RUNTIME' #{home}/.bashrc"
# end

# cargo = "#{home}/.cargo/bin/cargo"
#   # execute "#{sudo(node[:user])}ghq get helix-editor/helix"
#   execute 'install helix' do
# dir = File.join( ghq_root, "github.com/helix-editor/helix")
#     command <<-EOL
#       set -eu
#       #{sudo(node[:user])}cd #{dir}
#       #{cargo} install --path #{dir}/helix-term --locked
#     EOL
#     user user

#     not_if 'test -e /usr/local/bin/helix'
#   end

file "#{home}/.bashrc" do
  action :edit
  not_if "grep 'export EDITOR=hx' #{home}/.bashrc"
  content %(export EDITOR=hx)
end

zshrc_config = node[:zshrc_config]
file zshrc_config do
  action :edit
  not_if "grep 'export EDITOR=hx' #{zshrc_config}"
  content %(export EDITOR=hx)
end

include_cookbook "language_servers"
