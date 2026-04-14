case node[:platform]
when "debian","ubuntu","mint", "pop"
  package "swi-prolog"
when "darwin","osx"
  package "swi-prolog"
end
