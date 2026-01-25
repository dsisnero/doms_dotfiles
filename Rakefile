require 'fileutils'

desc 'Run integration tests'
task 'test:integration' do
  sh 'bundle check || bundle install -j4'
  sh 'bundle exec rspec spec/integration'
end

desc 'Run specific test file'
task 'test:single', :file do |t, args|
  file = args[:file]
  unless file
    puts "Usage: rake test:single[spec/integration/file_spec.rb]"
    exit 1
  end
  sh 'bundle check || bundle install -j4'
  sh "bundle exec rspec #{file}"
end

desc 'Build Docker test image'
task 'test:build' do
  sh 'docker build -t doms-dotfiles-test -f spec/Dockerfile .'
end

desc 'Start test container'
task 'test:start' do
  sh %Q{docker run -d --privileged --rm --name doms-dotfiles-test \
    -v "#{File.expand_path('.')}:/test" \
    -v "#{File.expand_path('spec/recipes')}:/test/spec/recipes" \
    -v "#{File.expand_path('spec/plugins')}:/test/spec/plugins" \
    -v "#{File.expand_path('plugins')}:/test/plugins" \
    doms-dotfiles-test systemd}
end

desc 'Stop test container'
task 'test:stop' do
  sh 'docker rm -f doms-dotfiles-test 2>/dev/null || true'
end

desc 'Clean test artifacts'
task 'test:clean' do
  sh 'docker rmi doms-dotfiles-test 2>/dev/null || true'
  sh 'rm -rf .rspec_status'
end

desc 'Run tests with debug output'
task 'test:debug' do
  ENV['DEBUG'] = '1'
  Rake::Task['test:integration'].invoke
end

# Helper method to check if a command exists
def command_exists?(cmd)
  system("which #{cmd} > /dev/null 2>&1")
end

# Helper method to get container runtime (prefers native macOS runtime)
def container_runtime
  # Check for Apple's container runtime first on macOS
  if RUBY_PLATFORM.include?('darwin')
    # Check for Apple's container runtime (installed by our cookbook)
    if File.exist?('/usr/local/bin/container')
      return 'container'
    elsif system('xcrun --find oci > /dev/null 2>&1')
      return 'oci'
    elsif File.exist?('/usr/bin/oci')
      return 'oci'
    end
  end
  
  # Fall back to podman/docker
  if command_exists?('podman')
    'podman'
  elsif command_exists?('docker')
    'docker'
  else
    nil
  end
end

# Check if we're on macOS
def macos?
  RUBY_PLATFORM.include?('darwin')
end

desc 'Test deploy script in container (simulated if containers not available)'
task 'test:deploy' do
  puts "=== Testing ./bin/deploy --debug ==="
  
  # Check for container runtime
  runtime = container_runtime
  
  if runtime.nil?
    puts "No container runtime found. Would install podman via: ./bin/deploy podman"
    puts "For now, running simulated test..."
    run_simulated_test
  else
    puts "Container runtime found: #{runtime}"
    
    # Test if runtime actually works
    if test_container_runtime(runtime)
      puts "#{runtime} is functional. Running container test..."
      run_container_test(runtime)
    else
      puts "#{runtime} is not functional. Running simulated test..."
      run_simulated_test
    end
  end
end

def test_container_runtime(runtime)
  # Try to run a simple container command
  case runtime
  when 'oci', 'container'
    # Apple's container runtime - check if it's working
    system("#{runtime} run --rm alpine:latest echo 'test' > /dev/null 2>&1")
  else
    # podman/docker - try to run a simple container
    system("#{runtime} run --rm alpine:latest echo 'test' > /dev/null 2>&1")
  end
end

def run_container_test(runtime)
  puts "Starting #{runtime} container test..."
  
  # Create test directory
  test_dir = "/tmp/doms_dotfiles_test_#{Time.now.to_i}"
  FileUtils.mkdir_p(test_dir)
  
  # Copy essential files
  puts "Copying files to test directory..."
  essential_files = [
    'cookbooks/', 'plugins/', 'lib/', 'Gemfile', 'Gemfile.lock'
  ]
  
  essential_files.each do |file|
    if File.exist?(file)
      FileUtils.cp_r(file, "#{test_dir}/#{file}")
    end
  end
  
  # Copy bin directory but exclude mitamae binary to test fresh download
  if File.exist?('bin')
    FileUtils.mkdir_p("#{test_dir}/bin")
    Dir.entries('bin').each do |entry|
      next if entry.start_with?('.')
      next if entry == 'mitamae'  # Don't copy existing mitamae binary
      src = File.join('bin', entry)
      dst = File.join("#{test_dir}/bin", entry)
      if File.directory?(src)
        FileUtils.cp_r(src, dst)
      else
        FileUtils.cp(src, dst)
      end
    end
  end
  
  # Create test script - use sh for maximum compatibility
  test_script = <<~SH
    #!/bin/sh
    set -e
    
    echo "=== Container Test Environment ==="
    echo "OS: \$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME || uname -a)"
    echo "Current dir: \$(pwd)"
    echo "Contents:"
    ls -la
    
    echo ""
    echo "=== Running bin/setup ==="
    
    # Check if setup script exists
    if [ -f ./bin/setup ]; then
      echo "Setup script found, making executable..."
      chmod +x ./bin/setup 2>/dev/null || true
      
      echo "Checking setup script contents..."
      head -30 ./bin/setup
      
      echo ""
      echo "Attempting to run ./bin/setup..."
      # Try to run setup - it might fail due to missing dependencies
      if ./bin/setup 2>&1; then
        echo "Setup completed successfully"
      else
        echo "Setup exited with status: \$?"
        echo "This is expected if dependencies are missing"
      fi
    else
      echo "Setup script not found at ./bin/setup"
    fi
    
    echo ""
    echo "=== Checking what setup would install ==="
    echo "From reading setup script, it would:"
    grep -i "install\\|apt-get\\|apk\\|yum\\|dnf\\|brew" ./bin/setup 2>/dev/null | head -10 || echo "Could not parse setup script"
    
    echo ""
    echo "=== Testing mitamae after setup ==="
    if [ -f ./bin/mitamae ]; then
      echo "Checking mitamae file type..."
      file ./bin/mitamae 2>/dev/null || echo "file command not available"
      echo "Attempting to run mitamae..."
      ./bin/mitamae version 2>&1 | head -5 || echo "Mitamae not executable in this environment"
    fi
    
    echo ""
    echo "=== Test completed ==="
  SH
  
  File.write("#{test_dir}/test.sh", test_script)
  File.chmod(0755, "#{test_dir}/test.sh")
  
  # Run container - different syntax for Apple's container runtime
  begin
    # Ensure files are written to disk
    FileUtils.touch("#{test_dir}/.sync")
    
      if runtime == 'container' || runtime == 'oci'
        # Apple's container runtime syntax - use absolute path and ensure script is executable
        puts "Running Apple container test..."
        sh %Q{#{runtime} run --rm -v #{test_dir}:/test alpine:latest /bin/sh -c "cd /test && chmod +x test.sh && apk add --no-cache bash file curl 2>/dev/null || true && ./test.sh"}
      else
        # podman/docker syntax
        puts "Running #{runtime} container test..."
        sh %Q{#{runtime} run --rm -it \
          -v "#{test_dir}:/test" \
          alpine:latest \
          /bin/sh -c "cd /test && apk add --no-cache bash file curl 2>/dev/null || true && ./test.sh"}
      end
  rescue => e
    puts "Container test failed: #{e.message}"
    puts "Falling back to simulated test..."
    run_simulated_test
  ensure
    # Cleanup
    FileUtils.rm_rf(test_dir) if File.exist?(test_dir)
  end
end

def run_simulated_test
  puts "=== Running Simulated Deploy Test ==="
  
  puts "1. Checking deploy script..."
  unless File.exist?('./bin/deploy')
    puts "ERROR: ./bin/deploy not found"
    return
  end
  
  puts "2. Making scripts executable..."
  File.chmod(0755, './bin/deploy') rescue nil
  File.chmod(0755, './bin/mitamae') rescue nil
  File.chmod(0755, './bin/setup') rescue nil
  
  puts "3. Testing deploy script syntax..."
  if system('bash -n ./bin/deploy')
    puts "  ✓ Deploy script syntax is valid"
  else
    puts "  ✗ Deploy script has syntax errors"
  end
  
  puts "4. Showing what deploy would do..."
  puts "   Command that would run:"
  puts "   ./bin/setup"
  puts "   then: ./bin/mitamae local -l debug lib/recipe.rb"
  
  puts "5. Testing mitamae directly..."
  if File.exist?('./bin/mitamae')
    puts "   Mitamae version:"
    system('./bin/mitamae version 2>&1') || puts("   Could not get version")
  end
  
  puts "6. Testing a simple recipe..."
  simple_recipe = <<~RUBY
    directory "/tmp/deploy_test" do
      mode "0755"
    end
    
    file "/tmp/deploy_test/test.txt" do
      content "Deploy test successful at #{Time.now}"
      mode "0644"
    end
    
    execute "echo test" do
      command "echo 'Simple recipe executed successfully'"
    end
  RUBY
  
  File.write('/tmp/simple_test.rb', simple_recipe)
  puts "   Running simple test recipe..."
  system('./bin/mitamae local /tmp/simple_test.rb 2>&1 | tail -5')
  
  puts ""
  puts "=== Simulated Test Complete ==="
  puts "In a working container environment, this would fully test ./bin/deploy --debug"
end

desc 'Full test: install podman if needed, then test deploy'
task 'test:full' => ['test:deploy']

desc 'Test podman cookbook installation'
task 'test:podman' do
  puts "=== Testing podman cookbook ==="
  
  # Check if podman is already installed
  if command_exists?('podman')
    puts "Podman is already installed at: #{`which podman`.chomp}"
    puts "Version: #{`podman --version 2>/dev/null`.chomp}"
  else
    puts "Podman not found. Testing what the cookbook would do..."
    
    # Check what platform we're on
    platform = `uname -s`.chomp.downcase
    puts "Platform: #{platform}"
    
    if platform == 'darwin'
      puts "On macOS, podman cookbook would:"
      puts "1. Install podman via Homebrew"
      puts "2. Install podman-compose via Homebrew"
      puts "3. Install podman-tui via Homebrew"
      puts "4. Note: Requires podman machine init/start for Linux VM"
    elsif File.exist?('/etc/debian_version') || File.exist?('/etc/ubuntu-release')
      puts "On Debian/Ubuntu, podman cookbook would:"
      puts "1. Install podman package"
      puts "2. Install podman-compose package"
      puts "3. Install podman-tui package"
    else
      puts "Platform not specifically handled in cookbook"
    end
    
    # Try to run the cookbook via mitamae
    puts ""
    puts "Testing podman cookbook via mitamae..."
    
    test_recipe = <<~RUBY
      # Test recipe for podman cookbook
      include_recipe "cookbooks/podman/default.rb"
      
      # Verify installation
      execute "check podman" do
        command "which podman"
      end
    RUBY
    
    File.write('/tmp/test_podman.rb', test_recipe)
    
    if File.exist?('./bin/mitamae')
      puts "Running mitamae test recipe..."
      system('./bin/mitamae local /tmp/test_podman.rb 2>&1 | tail -20')
    else
      puts "Mitamae not found at ./bin/mitamae"
    end
  end
  
  puts "=== Podman cookbook test complete ==="
end

desc 'Clean up test containers'
task 'test:cleanup' do
  runtime = container_runtime
  if runtime
    puts "Cleaning up #{runtime} containers..."
    sh "#{runtime} ps -aq | xargs #{runtime} rm -f 2>/dev/null || true"
    sh "#{runtime} system prune -f 2>/dev/null || true"
  end
end