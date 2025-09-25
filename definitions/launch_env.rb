define :launch_env, value: nil, persistent: true do
  name = params[:name]
  value = params[:value]
  persistent = params[:persistent]

  if node[:platform] == "darwin"
    # Set environment variable immediately
    execute "setenv #{name} immediately" do
      command "launchctl setenv #{name} '#{value}'"
      user node[:user]
      not_if "[ \"$(launchctl getenv #{name})\" = '#{value}' ]"
    end

    if persistent
      # Create LaunchAgent plist for persistence
      plist_filename = "setenv.#{name}.plist"
      plist_path = File.expand_path("~/Library/LaunchAgents/#{plist_filename}")

      plist_content = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>setenv.#{name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>/bin/launchctl</string>
            <string>setenv</string>
            <string>#{name}</string>
            <string>#{value}</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
        </plist>
      XML

      file plist_path do
        content plist_content
        owner node[:user]
        group node[:group]
        mode "644"
      end

      # Load the plist if it's not already loaded
      execute "load launch agent for #{name}" do
        command "launchctl load -w #{plist_path}"
        user node[:user]
        not_if "launchctl list | grep -q setenv.#{name}"
      end
    end
  end
end
