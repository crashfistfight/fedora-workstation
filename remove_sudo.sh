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


### config user ###
# set root password
echo "root:$root_password" | chpasswd

# remove user from group
usermod -rG wheel "$user"

# create groups
groupadd plugdev

# add user to group
usermod -aG systemd-journal,libvirt,plugdev "$user"

# create polkit rule for group diskadmin
#tee /etc/polkit-1/rules.d/80-udisks2.rules > /dev/null <<EOF
#polkit.addRule(function(action, subject) {
#    if (action.id == "org.freedesktop.udisks2.encrypted-unlock-system" || action.id == "org.freedesktop.udisks2.filesystem-mount-system" || action.id == "org.freedesktop.udisks2.filesystem-unmount-system" &&
#        subject.active == true && subject.local == true &&
#        subject.isInGroup("diskadmin"))
#        {
#        return polkit.Result.YES;
#    }
#});
#EOF


### remove sudo ###
# unlock package
mv /etc/dnf/protected.d/{sudo.conf,sudo.conf.unlock}

# remove package
dnf remove --assumeyes sudo


### self destroy ###
# delete script
#rm -- "${BASH_SOURCE[0]}"