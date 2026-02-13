# DeepWiki Q&A with Code Context for Repository: itamae-kitchen/mitamae

## Q1

what specinfra commands are available to use in plugins

### Answer

In mitamae plugins, you can access Specinfra commands through the runner/backend
interface provided to resource executors. The primary methods are
`run_specinfra(type, *args)` to execute commands and `get_command(type, *args)`
to retrieve platform-specific command strings mitamae:172-185.

## Available Specinfra Commands

Specinfra commands are accessed by their type symbols. The system first checks
if an inline backend can handle the operation, then falls back to Specinfra
command execution mitamae:172-185.

### File Operations

- `:get_file_mode, path` - Get file permissions mitamae:48-48
- `:change_file_mode, path, mode` - Change file permissions mitamae:13-13
- `:get_file_owner_user, path` - Get file owner mitamae:50-50
- `:get_file_owner_group, path` - Get file group mitamae:51-51
- `:change_file_owner, path, user, group` - Change file ownership mitamae:17-17
- `:move_file, src, dest` - Move file mitamae:22-22
- `:copy_file, src, dest` - Copy file mitamae:25-25

### Service Operations

- `:check_service_is_running, name` - Check if service is running mitamae:38-38
- `:check_service_is_enabled, name` - Check if service is enabled mitamae:39-39

### User Operations

- `:check_user_exists, name` - Check if user exists mitamae:24-24
- `:get_user_uid, name` - Get user UID mitamae:28-28
- `:get_user_gid, name` - Get user GID mitamae:32-32
- `:get_user_home_directory, name` - Get user home directory mitamae:36-36
- `:get_user_login_shell, name` - Get user login shell mitamae:40-40

## Usage in Plugins

In your plugin resource executors, access these commands through the runner:

```ruby
def some_action
  # Execute a specinfra command
  result = run_specinfra(:get_file_mode, '/path/to/file')

  # Get the command string without executing
  command = get_command(:check_service_is_running, 'nginx')

  # Check commands return boolean
  if run_specinfra(:check_user_exists, 'myuser')
    # user exists
  end
end
```

``
