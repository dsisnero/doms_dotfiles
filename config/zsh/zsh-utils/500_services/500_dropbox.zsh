
# Dropbox utility functions

# Download files from Dropbox shared links
# Handles Dropbox's URL parameters and decodes URL-encoded filenames
# Usage: db_download [dropbox_shared_link]
db_download()
{
  target=${1}
  # Remove Dropbox's '?dl=0' parameter from filename
  target_filename=$(basename ${target} | sed "s/?dl=0//g")
  # Decode URL-encoded characters in filename (requires urldecode function)
  decoded_name=$(urldecode $target_filename)
  # Download file with the decoded filename
  wget ${target} -O ${decoded_name}
}
