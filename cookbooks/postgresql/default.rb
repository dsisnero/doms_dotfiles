include_recipe "./dependency.rb"

node.reverse_merge!({
  postgresql: {
    version: "", # Empty = use metapackages to get latest. Set to "16" to pin.
    port: 5432,
    data_dir: "/var/lib/postgresql/data",
    user: "postgres" # passwords are handled via environment variables:
    # - PG_PASSWORD for postgres superuser
    # - PGUSER_PASSWORD for application user
  }
})

version = node[:postgresql][:version]
pg_suffix = version.empty? ? "" : "-#{version}"
pg_suffix_at = version.empty? ? "" : "@#{version}"
node[:postgresql][:port]
data_dir = node[:postgresql][:data_dir]
postgres_user = node[:postgresql][:user]

# PostgreSQL superuser password (for postgres user)
postgres_superuser_password = ENV["PG_PASSWORD"] || ""

case node[:platform]
when "debian", "ubuntu", "mint"
  package "postgresql#{pg_suffix}"
  package "postgresql-contrib#{pg_suffix}"
  package "libpq-dev"

  unless node[:is_wsl]
    service "postgresql" do
      action %i[start enable]
    end
  end
when "fedora", "redhat", "amazon"
  package "postgresql-server"
  package "postgresql-contrib"
  package "postgresql-devel"

  # Initialize database if not already done
  execute "postgresql-setup initdb" do
    not_if { File.directory?("/var/lib/pgsql/data") }
  end

  unless node[:is_wsl]
    service "postgresql" do
      action %i[start enable]
    end
  end
when "arch"
  package "postgresql"

  # Initialize database if not already done
  execute "sudo -u postgres initdb --locale en_US.UTF-8 -E UTF8 -D '#{data_dir}'" do
    not_if { File.directory?(data_dir) }
  end

  unless node[:is_wsl]
    service "postgresql" do
      action %i[start enable]
    end
  end
when "osx", "darwin"
  package "postgresql#{pg_suffix_at}"

  # Determine paths for PostgreSQL binaries
  pg_bin = if File.exist?("/opt/homebrew/opt/postgresql#{pg_suffix_at}/bin/psql")
    "/opt/homebrew/opt/postgresql#{pg_suffix_at}/bin"
  elsif File.exist?("/usr/local/opt/postgresql#{pg_suffix_at}/bin/psql")
    "/usr/local/opt/postgresql#{pg_suffix_at}/bin"
  else
    "" # Fallback to hoping it's in PATH
  end

  unless node[:is_wsl]
    brew_path = if File.exist?("/opt/homebrew/bin/brew")
      "/opt/homebrew/bin/brew"
    else
      "/usr/local/bin/brew"
    end

    execute "start and enable postgresql" do
      command "#{brew_path} services start postgresql#{pg_suffix_at}"
      user node[:user]
      not_if "#{brew_path} services list | grep postgresql#{pg_suffix_at} | grep -q started"
    end
  end
when "opensuse"
  package "postgresql#{version}"
  package "postgresql#{version}-contrib"
  package "postgresql#{version}-devel"

  unless node[:is_wsl]
    service "postgresql" do
      action %i[start enable]
    end
  end
end

# Create user and database if not exists
# Use PGUSER_PASSWORD for the application user
pguser_password = ENV["PGUSER_PASSWORD"]

unless pguser_password
  raise "PGUSER_PASSWORD environment variable is required but not set"
end

case node[:platform]
when "osx", "darwin"
  # On macOS with Homebrew, current user is already the superuser
  # Create user if not exists, set password, and ensure database exists

  execute "create current user if not exists" do
    command %(#{pg_bin}/psql -d postgres -c "CREATE USER #{node[:user]};")
    not_if %(#{pg_bin}/psql -d postgres -c "\\du" | grep -q #{node[:user]})
  end

  execute "set current user password" do
    command %(#{pg_bin}/psql -d postgres -c "ALTER USER #{node[:user]} WITH PASSWORD '#{pguser_password}';")
  end

  execute "create database for user" do
    command %(#{pg_bin}/createdb #{node[:user]})
    not_if %(#{pg_bin}/psql -d postgres -l | grep -q #{node[:user]})
  end

  # Set PostgreSQL superuser password (using PG_PASSWORD) if provided
  if postgres_superuser_password && !postgres_superuser_password.empty?
    execute "create postgres superuser and set password" do
      command %(#{pg_bin}/psql -d postgres -c "CREATE USER postgres WITH SUPERUSER PASSWORD '#{postgres_superuser_password}';")
      not_if %(#{pg_bin}/psql -d postgres -c "\\du" | grep -q postgres)
    end
  end
else
  # Original logic for other platforms
  if pguser_password && !pguser_password.empty?
    execute "create postgres user" do
      user postgres_user
      command %(psql -c "CREATE USER #{node[:user]} WITH PASSWORD '#{pguser_password}';")
      not_if %(psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='#{node[:user]}'" | grep -q 1)
    end

    execute "update postgres user password" do
      user postgres_user
      command %(psql -c "ALTER USER #{node[:user]} WITH PASSWORD '#{pguser_password}';")
    end
  end

  execute "create database for user" do
    user postgres_user
    command %(createdb #{node[:user]})
    not_if %(psql -l | grep -q #{node[:user]})
  end

  # Grant database creation privileges to user
  execute "grant database creation privileges" do
    user postgres_user
    command %(psql -c "ALTER USER #{node[:user]} CREATEDB;")
    not_if %(psql -tAc "SELECT rolcreatedb FROM pg_roles WHERE rolname='#{node[:user]}'" | grep -q t)
  end

  # Grant full privileges on user's own database
  execute "grant full privileges on user database" do
    user postgres_user
    command %(psql -c "GRANT ALL PRIVILEGES ON DATABASE #{node[:user]} TO #{node[:user]};")
  end

  # Grant schema creation privileges in user's database
  execute "grant schema creation privileges" do
    user postgres_user
    command %(psql -d #{node[:user]} -c "GRANT CREATE ON SCHEMA public TO #{node[:user]};")
  end

  # Set PostgreSQL superuser password (using PG_PASSWORD) if provided
  if postgres_superuser_password && !postgres_superuser_password.empty?
    execute "set postgres superuser password" do
      user postgres_user
      command %(psql -c "ALTER USER postgres WITH PASSWORD '#{postgres_superuser_password}';")
    end
  end
end

# Install useful PostgreSQL tools
case node[:platform]
when "debian", "ubuntu", "mint"
  package "pgcli"
when "fedora", "redhat", "amazon"
  package "pgcli"
when "arch"
  package "pgcli"
when "osx", "darwin"
  execute "install pgcli via pip" do
    command "pip install pgcli"
    not_if "which pgcli"
  end
end
