case node[:platform]
when "debian","ubuntu","mint", "pop"
  package "libfuse2"
end
