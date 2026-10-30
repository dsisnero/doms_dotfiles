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
# Languages helix does not ship (crystal today) are declared by hand in
# cookbooks/dotfiles/templates/helix/languages.toml.erb; without the fetch/build
# below the parser is never installed.
helix_languages = File.join(config_home, "helix", "languages.toml")
grammar_root = File.join(config_home, "helix", "runtime", "grammars")
dylib_ext = windows? ? "dll" : "so"

# [[grammar]] entries as rendered into languages.toml, as [name, rev, subpath].
# The template writes them as inline tables, e.g.
#   source = { git = "https://...", rev = "abc123", subpath = "tree-sitter-x" }
declared_grammars = []
if File.exist?(helix_languages)
  entry = nil
  File.read(helix_languages).each_line do |line|
    stripped = line.strip
    if stripped.start_with?("[[grammar]]")
      entry = [nil, nil, nil]
      declared_grammars << entry
    elsif stripped.start_with?("[")
      entry = nil
    elsif entry && stripped.start_with?("name = ")
      match = stripped.match(/name = "([^"]+)"/)
      entry[0] = match[1] if match
    elsif entry && stripped.start_with?("source = ")
      match = stripped.match(/rev = "([^"]+)"/)
      entry[1] = match[1] if match
      match = stripped.match(/subpath = "([^"]+)"/)
      entry[2] = match[1] if match
    end
  end
  declared_grammars = declared_grammars.select { |grammar| grammar[0] }
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
  # Guards run at resource-run time (and are lambdas so `run_command` runs in
  # recipe context): after `--grammar fetch` sees a rev mismatch it *deletes* and
  # re-clones the grammar dir, so a stale `.so` is only visible once fetch ended.
  grammar_source_dir = lambda do |grammar|
    File.join(grammar_root, "sources", grammar[0])
  end

  # A grammar is current when its source is checked out at the pinned rev. A
  # branch/tag pin (asciidoc uses rev = "master") can't be compared to a HEAD sha
  # without hitting the network, so it only has to exist.
  grammars_current = lambda do
    declared_grammars.all? do |grammar|
      rev = grammar[1]
      source_dir = grammar_source_dir.call(grammar)
      if !File.directory?(source_dir)
        false
      elsif rev && rev.match(/\A[0-9a-f]{7,40}\z/)
        run_command("git -C #{source_dir} rev-parse HEAD", error: false).stdout.strip.start_with?(rev)
      else
        true
      end
    end
  end

  # Built when the parser library exists and is not older than the parser source
  # (this mirrors helix's own needs_recompile check, and is why a re-cloned
  # grammar recompiles).
  grammars_built = lambda do
    declared_grammars.all? do |grammar|
      name = grammar[0]
      source_dir = grammar_source_dir.call(grammar)
      source_dir = File.join(source_dir, grammar[2]) if grammar[2]
      lib = File.join(grammar_root, "#{name}.#{dylib_ext}")
      parser = File.join(source_dir, "src", "parser.c")
      if File.exist?(lib) && File.exist?(parser)
        File.stat(lib).mtime >= File.stat(parser).mtime
      else
        false
      end
    end
  end

  # fetch is all-or-nothing (it re-clones every grammar in the merged config), so
  # it runs when any declared grammar is missing or not at its pinned rev: first
  # install, a newly declared language, or a bumped rev in the template. It also
  # fails wholesale when *any* upstream grammar repo has moved or vanished, which
  # is common enough that it must not abort the run: our own grammars are
  # verified below instead.
  execute "helix fetch grammars" do
    command "#{hx_cmd} --grammar fetch || echo 'helix: some grammars failed to fetch, continuing'"
    user node[:user]
    not_if { grammars_current.call }
  end

  # build sweeps every grammar but is incremental, so it is cheap once current.
  execute "helix build grammars" do
    command "#{hx_cmd} --grammar build || echo 'helix: some grammars failed to build, continuing'"
    user node[:user]
    not_if { grammars_built.call }
  end

  # ... but a declared grammar is not optional: without its parser the language
  # silently degrades to plain text. This only runs when the parser is missing, so
  # it is silent on healthy runs and loud when fetch/build could not deliver.
  declared_grammars.each do |grammar|
    name = grammar[0]
    lib = File.join(grammar_root, "#{name}.#{dylib_ext}")

    execute "helix verify #{name} grammar" do
      command "echo 'helix: #{name} parser is missing (#{lib}); " \
        "run `hx --grammar fetch` and `hx --grammar build` and check the output' >&2; exit 1"
      user node[:user]
      not_if { File.exist?(lib) }
    end
  end
end

# --- queries ----------------------------------------------------------------
# A grammar is only half of tree-sitter support: `--grammar fetch/build` produces
# the parser (<name>.so) and nothing else. Helix resolves highlighting from
# runtime/queries/<lang>/*.scm across its runtime dirs, and it never copies the
# queries a grammar repo may ship (they are editor specific - see
# https://github.com/helix-editor/helix/discussions/11379). So any language helix
# does not ship itself needs its .scm files installed. Ours live in
# config/helix/queries/<lang> and are linked next to the parsers.
queries_src_root = File.join(doms_dotfiles, "config", "helix", "queries")
queries_dest_root = File.join(config_home, "helix", "runtime", "queries")

if File.directory?(queries_src_root)
  # not mydir: the runtime lives in the helix checkout, which may sit on a
  # filesystem that ignores chmod, and a directory resource would then report a
  # change on every run.
  execute "helix create runtime queries dir" do
    command "mkdir -p #{queries_dest_root}"
    user node[:user]
    not_if { File.directory?(queries_dest_root) }
  end

  (Dir.entries(queries_src_root).sort - [".", ".."]).each do |lang|
    query_src = File.join(queries_src_root, lang)
    next unless File.directory?(query_src)

    query_dest = File.join(queries_dest_root, lang)
    # ln -sfn: replace our own link if it points elsewhere (moved checkout), but
    # -n keeps ln from linking *inside* an existing directory symlink.
    execute "helix link #{lang} queries" do
      command "ln -sfn #{query_src} #{query_dest}"
      user node[:user]
      not_if do
        if File.symlink?(query_dest)
          File.readlink(query_dest) == query_src
        else
          # a real directory means helix ships its own queries: leave them alone
          File.exist?(query_dest)
        end
      end
    end
  end
end

# every grammar we declare must have queries somewhere, otherwise the parser
# loads but nothing highlights. This catches languages added to
# cookbooks/dotfiles/templates/helix/languages.toml.erb without .scm files.
declared_grammars.map { |grammar| grammar[0] }.uniq.each do |grammar|
  next if File.directory?(File.join(queries_dest_root, grammar))

  MItamae.logger.warn "helix: grammar '#{grammar}' has no queries in #{queries_dest_root}, " \
    "so it will parse but not highlight. Add config/helix/queries/#{grammar}/"
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
