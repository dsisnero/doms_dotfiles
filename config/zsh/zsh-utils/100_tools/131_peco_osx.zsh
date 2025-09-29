# macOS-specific Peco utility functions

# Navigate to work directories using fuzzy finder
# Searches ~/work directory (max depth 2) and changes to selected directory
peco_work() {
    target=`find ~/work -maxdepth 2 -mindepth 1 -type d | peco`
    echo $target
    cd $target
}

# Launch Genymotion Android emulator using fuzzy finder to select VM
# Lists all VirtualBox VMs and boots the selected one in Genymotion
genymotion_peco() {
    if [ -z "$GENYMOTION_APP_HOME" ]
    then
        echo "GENYMOTION_APP_HOME is empty. Use '/Applications/Genymotion.app/' instead this time."
        player="/Applications/Genymotion.app/Contents/MacOS/player"
    else
        player="$GENYMOTION_APP_HOME/Contents/MacOS/player"
    fi
    vm_name=`VBoxManage list vms | peco`
    if [[ $vm_name =~ ^\"(.+)\".* ]]
    then
        name=${match[1]}
        echo "boot $name"
        $player --vm-name "$name" &
    fi
}


