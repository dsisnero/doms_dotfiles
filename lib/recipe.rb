# FIRST configure Specinfra before any platform detection
require 'specinfra'
Specinfra.configuration.os[:family] = 'ubuntu' if node[:platform] == 'pop'

# THEN define the command module
module Specinfra
  module Command
    module Pop
      class Base < Specinfra::Command::Ubuntu::Base
      end
    end
  end
end

include_recipe "recipe_helper"

# FINALLY set platform override
node[:platform] = "ubuntu" if node[:platform] == "pop"
include_role node[:platform]
