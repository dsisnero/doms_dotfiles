# Media role - include media-related cookbooks
package "vlc"
package "handbrake"
package "ffmpeg"

# Additional media packages for Debian-based systems
if platform_family == "debian"
  package "ubuntu-restricted-extras"
end
