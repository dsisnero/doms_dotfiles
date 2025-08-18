require 'pathname'
ROOT = Pathname.getwd

namespace :rbs do
  task setup: %i[clean collection prototype subtract]

  task :clean do
    rm_rf 'sig/rbs_rails/'
    rm_rf 'sig/prototype/'
    rm_rf '.gem_rbs_collection/'
  end

  task :collection do
    collection_file = ROOT / 'rbs_collection.yaml'
    sh 'rbs', 'collection', 'init' unless collection_file.exist?
    sh 'rbs', 'collection', 'install'
  end

  task :prototype do
    sh 'rbs', 'prototype', 'rb', '--out-dir=sig/prototype', '--base-dir=.', 'app', 'lib'
  end

  task :subtract do
    sh 'rbs', 'subtract', '--write', 'sig/prototype', 'sig/generated'

    # prototype_path = Rails.root.join('sig/prototype')
    prototype_path = Pathname('sig/prototype')
    # rbs_rails_path = Rails.root.join('sig/rbs_rails')
    subtrahends = Pathname.glob('sig/*')
      .reject { |path| path == prototype_path }
      .map { |path| "--subtrahend=#{path}" }
    sh 'rbs', 'subtract', '--write', 'sig/prototype', *subtrahends
  end

  task :validate do
    sh 'rbs', '-Isig', 'validate', '--silent'
  end
end
