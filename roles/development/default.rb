# Development role - include development-specific cookbooks
# Desktop role includes git, rust, golang, python, ruby, crystal, zig, etc.
# Add additional development tools and services
include_cookbook "mise"

include_cookbook "docker"
include_cookbook "postgresql"
include_cookbook "nodejs"
include_cookbook "java"
include_cookbook "terraform"
include_cookbook "aws-cli"
include_cookbook "github-cli"
include_cookbook "ollama"
include_cookbook "ngrok"
include_cookbook "shellcheck"
include_cookbook "hadolint"
include_cookbook "openssh"
include_cookbook "clang"
include_cookbook "llvm"
include_cookbook "golang"
include_cookbook "zig"
include_cookbook "vscode"
include_cookbook "myrepos"
include_cookbook "language_servers"
