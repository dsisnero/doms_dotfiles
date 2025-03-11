# frozen_string_literal: true

include_cookbook "mise"

execute "install go" do
  user node[:user]
  command "mise use -g go"
end
