case node[:platform]
when "debian", "ubuntu", "mint", "pop"
  # swi-prolog meta-package → swi-prolog-nox → swi-prolog-core (libswipl.so)
  package "swi-prolog"
when "darwin", "osx"
  # Homebrew: includes libswipl.dylib + headers + swipl.pc
  package "swi-prolog"
when "fedora", "redhat", "amazon"
  # Fedora: package name is "pl" which provides libswipl.so + headers
  package "pl"
when "arch"
  package "swi-prolog"
when "opensuse"
  package "swi-prolog"
when "windows"
  chocolatey_package "swi-prolog"
end
