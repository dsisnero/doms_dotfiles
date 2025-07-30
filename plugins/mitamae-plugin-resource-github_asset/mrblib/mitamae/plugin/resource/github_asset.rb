module MItamae
  module Plugin
    module Resource
      class GitHubAsset < ::MItamae::Resource::Base
        define_attribute :action, default: :download
        define_attribute :repo, type: String, required: true
        define_attribute :version, type: String, default: 'latest'
        define_attribute :asset_pattern, type: String, required: true
        define_attribute :download_path, type: String, required: true
        define_attribute :user, type: String
        define_attribute :group, type: String
        define_attribute :mode, type: String

        self.available_actions = [:download]
      end
    end
  end
end
