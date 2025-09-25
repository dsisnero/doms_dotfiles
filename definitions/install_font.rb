define :install_font do
  name = params[:name]
  # typename = File.extname(name) == 'otf' ? 'OTF' : 'TTF'
  install_path = "~/.local/share/fonts"

  directory install_path
  execute "cp #{name} #{install_path}"
end
