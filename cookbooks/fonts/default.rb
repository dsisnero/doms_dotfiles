home = node[:home]
user = node[:user]
share_dir = "#{home}/.local/share"

wanted_fonts = %w[
  BitstreamVeraSansMono
  CodeNewRoman
  DroidSansMono
  FiraCode
  FiraMono
  Go-Mono
  Hack
  Hermit
  JetBrainsMono
  Meslo
  Noto
  Overpass
  ProggyClean
  RobotoMono
  SourceCodePro
  SpaceMono
  Ubuntu
  UbuntuMono
]

node.reverse_merge!(
  nerd_fonts: {
    version: "3.2.1",
    fonts: wanted_fonts,
    fonts_dir: "#{share_dir}/fonts"
  }
)
nerd_fonts = node[:nerd_fonts]
version = nerd_fonts[:version]
fonts = nerd_fonts[:fonts].map { _1.chomp }
shared_fonts_dir = nerd_fonts[:fonts_dir]

case node[:platform]
when "arch"
  include_cookbook "yay"
  yay "noto-fonts-emoji"
  yay "nerd-fonts-complete"

when "osx", "darwin"
  # not implemented
when "fedora", "redhat", "amazon"
  # not implemented
when "debian", "ubuntu", "mint"
  package "fonts-firacode"
  package "fonts-noto-cjk"
  package "fonts-noto-cjk-extra"

  mydir shared_fonts_dir

  workdir = "#{home}/fontsworkdir"

  mydir workdir

  font_extensions = %w[ttf otf woff woff2]

  fonts.each do |font|
    zip_file = "#{font}.zip"
    download_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v#{version}/#{zip_file}"
    downloaded_file = "#{workdir}/#{zip_file}"
    fonts_dir = "#{shared_fonts_dir}/#{font}"

    http_request "downloaded font file #{font}" do
      url download_url
      path downloaded_file
      owner user
      notifies :run, "execute[install font file #{font}]", :immediately
      only_if { Dir.glob("#{fonts_dir}/***.{#{font_extensions.join(",")}}").empty? }
    end

    execute "install font file #{font}" do
      cwd workdir
      command "unzip -oq #{zip_file} -d #{fonts_dir}"
      user user
      action :nothing
    end
  end

  execute("fc-cache -fv") do
    user user
  end

  # find "$shared_fonts_dir" -name '*Windows Compatible*' -delete

  # execute "rm -rf #{workdir}"
when "opensuse"
  # not implemented
end
