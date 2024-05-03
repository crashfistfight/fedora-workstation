#! /usr/bin/env bash

### config options ###
# vars
user=''
root_password=''


### tests ###
if [[ ! "$EUID" = "0" ]]; then
    echo "Please run as root, exiting..."
    sleep 2
    exit
fi

if [[ -z "$user" ]]; then
    echo "Variable user is emtpy, exiting..."
    sleep 2
    exit
fi

if [[ -z "$root_password" ]]; then
    echo "Variable root_password is emtpy, exiting..."
    sleep 2
    exit
fi


### remove sudo ###
# set root password
echo "root:$root_password" | chpasswd

# remove user from group
usermod -rG wheel "$user"

# add user to group
usermod -aG systemd-journal,libvirt,plugdev "$user"

# unlock package
mv /etc/dnf/protected.d/{sudo.conf,sudo.conf.unlock}

# remove package
dnf remove --assumeyes sudo


### self destroy ###
# delete script
#rm -- "${BASH_SOURCE[0]}"