module Specinfra
  module Command
    module Pop
      class Base < Specinfra::Command::Ubuntu::Base
      end
    end
  end
end

include_recipe "recipe_helper"

# Keep this line to treat Pop as Ubuntu for package management
node[:platform] = "ubuntu" if node[:platform] == "pop" 
include_role node[:platform]
