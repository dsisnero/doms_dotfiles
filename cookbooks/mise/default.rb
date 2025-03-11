include_recipe "dependency.rb"

user_ = node[:user]
home_ = node[:home]

case node[:platform]
when "debian", "mint", "ubuntu"

  execute "install mise" do
    command <<~EOCMD
      wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg
      echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
    EOCMD
    not_if "test -f /etc/apt/sources.list.d/mise.list"
  end

  execute "sudo apt update"

  package "mise"

  file "#{home_}/.bashrc" do
    action :edit
    block do |content|
      content << %[eval "$(mise activate bash)"]
    end
    not_if %(grep 'mise activate' #{home_}/.bashrc)
  end

  file "#{home_}/.zshrc" do
    action :edit
    block do |content|
      content << %[eval "$(mise activate zsh)"]
    end
    not_if %(grep 'mise activate' #{home_}/.zshrc)
  end

  fish_config = "#{home_}/.config/fish/config.fish"

  file fish_config do
    action :edit
    block do |content|
      content << %(mise activate zsh | source")
    end
    not_if %(grep 'mise activate' #{fish_config})
  end

when "fedora", "redhat", "amazon"

when "osx", "darwin"
end
