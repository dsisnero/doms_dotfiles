case node[:platform]
when "debian", "ubuntu", "mint", "pop"
when "darwin"
  package "java"

  src = "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk"
  dst = "/Library/Java/JavaVirtualMachines/openjdk.jdk"

  link dst do
    to src
    not_if { File.directory? dst }
    user "root"
  end
end
