module MItamae
  module Plugin
    module ResourceExecutor
      class GitHubAsset < ::MItamae::ResourceExecutor::Base
        def apply
          return unless desired.download?
          release = fetch_release_data
          asset = find_matching_asset(release['assets'])
          download_file(asset['browser_download_url'])
          set_file_attributes
        end

        private

        def fetch_release_data
          tag = attributes.version == 'latest' ? 'latest' : "tags/#{attributes.version}"
          url = "https://api.github.com/repos/#{attributes.repo}/releases/#{tag}"

          http_request "github_api_#{attributes.name}" do
            url url
            headers({"Accept" => "application/vnd.github.v3+json"})
            action :get
            notifies :run, "ruby_block[parse_release_data_#{attributes.name}]"
          end

          ruby_block "parse_release_data_#{attributes.name}" do
            block do
              node.run_state[attributes.name] = JSON.parse(run_command("cat /tmp/mitamae_github_api_#{attributes.name.shellescape}.json").stdout)
            end
            action :nothing
          end

          node.run_state[attributes.name] || {}
        end

        def find_matching_asset(assets)
          pattern = attributes.asset_pattern
            .gsub(':version', attributes.version)
            .gsub(':os', node[:platform])
            .gsub(':arch', node[:kernel][:machine])

          asset = assets.find { |a| File.fnmatch?(pattern, a['name']) }
          asset || raise("No matching asset found for pattern: #{pattern}")
        end

        def download_file(url)
          http_request "download_#{attributes.name}" do
            url url
            path attributes.download_path
            action :create
            mode attributes.mode if attributes.mode
          end
        end

        def set_file_attributes
          file attributes.download_path do
            owner attributes.user if attributes.user
            group attributes.group if attributes.group
            only_if { File.exist?(attributes.download_path) }
          end
        end
      end
    end
  end
end
