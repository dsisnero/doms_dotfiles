# List Vagrant virtual machine names from the current directory
# Parses 'vagrant status' output to extract just the VM names
vagrant_list()
{
  vagrant status | tail -n +3 | head -n -4 | awk '{print $1}'
}
