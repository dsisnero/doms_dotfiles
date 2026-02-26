include_recipe "dependency.rb"

case node[:platform]
when "darwin", "osx"
  package "smlnj"
  MItamae.logger.warn "smlnj has been deprecated because it does not pass the macOS Gatekeeper check! It will be disabled on 2026-09-01."

  # Add /usr/local/smlnj/bin to PATH in shell config
  smlnj_bin_path = "/usr/local/smlnj/bin"
  zshrc_config = node[:zshrc_config]

  file zshrc_config do
    action :edit
    only_if "test -d #{smlnj_bin_path}"
    not_if "grep 'export PATH=.*#{smlnj_bin_path}' #{zshrc_config}"
    content %(export PATH=#{smlnj_bin_path}:$PATH)
  end
when "debian", "ubuntu", "mint", "pop"
  package "smlnj"
when "fedora", "redhat", "amazon"
  package "smlnj"
when "arch"
  # smlnj might be in AUR; for now skip
  log "smlnj not implemented for Arch"
when "windows"
  log "smlnj not implemented for Windows"
else
  log "smlnj not implemented for platform #{node[:platform]}"
end
