home = node[:home]
user = node[:user]

case node[:platform]
when "debian", "ubuntu", "mint", "pop", "darwin", "osx", "fedora", "redhat", "amazon", "arch", "opensuse"
  execute "install codex" do
    command "curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=true sh"
    not_if "test -f #{home}/.local/bin/codex"
    user user
  end
when "windows"
  execute "install codex" do
    command "powershell -ExecutionPolicy ByPass -c \"$env:CODEX_NON_INTERACTIVE='true'; irm https://chatgpt.com/codex/install.ps1 | iex\""
    not_if "where codex"
  end
end
