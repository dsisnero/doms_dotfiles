module MItamae
  module Plugin
    module Resource
      class GitHubBin < MItamae::Resource::Base
        define_attribute :action, default: :install
        define_attribute :name, type: String, default_name: true
        define_attribute :binary_name, type: String
        define_attribute :user, type: String

        self.available_actions = [:install]

        def download_and_install
          require "json"
          require "net/http"
          require "uri"

          # Fetch the latest release information from GitHub
          uri = URI("https://api.github.com/repos/#{name}/releases/latest")
          response = Net::HTTP.get(uri)
          release_data = JSON.parse(response)

          download_url = get_asset(release_data)
          download_asset(download_url)
          install_asset("/tmp/#{binary_name}")
        end

        private

        def get_asset(data)
          platform = node[:platform]
          cputype = `uname -m`.strip
          platform_map = {
            "ubuntu" => "Linux",
            "debian" => "Linux",
            "mint" => "Linux",
            "arch" => "Linux",
            "darwin" => "Darwin",
            "osx" => "Darwin",
            "windows" => "Windows"
          }
          platform_str = platform_map[platform] || platform.capitalize
          x86_compat = %w[x86_64 amd64]
          assets = if x86_compat.include? cputype
            x86_compat.flat_map do |type|
              data["assets"].select { |a| a["name"] =~ /#{platform_str}/i && a["name"].include?(type) }
            end
          else
            data["assets"].select { |a| a["name"] =~ /#{platform_str}/i && a["name"].include?(cputype) }
          end
          asset = if platform == "ubuntu"
            assets.find { |a| a["name"].end_with?(".deb") } || assets.find { |a| a["name"].end_with?(".tar.gz") }
          else
            assets.first
          end
          asset ? asset["browser_download_url"] : nil
        end

        def download_asset(url)
          system("curl -L -o /tmp/#{binary_name} #{url}")
        end

        def install_asset(file_path)
          case file_path
          when /\.tar\.gz$/
            system("tar -xzf #{file_path} -C /tmp")
            system("mv /tmp/#{binary_name} /usr/local/bin/#{binary_name}")
          when /\.deb$/
            system("sudo dpkg -i #{file_path}")
          when /\.zip$/
            system("unzip #{file_path} -d /tmp")
            system("mv /tmp/#{binary_name} /usr/local/bin/#{binary_name}")
          else
            system("chmod +x #{file_path}")
            system("mv #{file_path} /usr/local/bin/#{binary_name}")
          end
          system("chown #{user}:#{user} /usr/local/bin/#{binary_name}")
        end
      end
    end
  end
end
