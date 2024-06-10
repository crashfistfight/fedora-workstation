#! /usr/bin/env bash

# shellcheck disable=SC2154,SC1091

### config options ###
# vars
source vars/all


### tests ###
if [[ ! "$EUID" = "0" ]]; then
    echo "Please run as root, exiting..."
    sleep 2
    exit
fi

if ! mount | grep -oq '/home type btrfs'; then
    echo "/home is not a btrfs subvolume, exiting..."
    sleep 2
    exit
fi


### dnf ###
# remove, update and install packages
required_packages=(
  'snapper'
  'vim'
  'nautilus'
)

dnf autoremove --assumeyes "${removals[@]}"
dnf update --assumeyes
dnf install --assumeyes "${required_packages[@]}" "${packages[@]}"

# configure system updates
#sed --in-place "s@^apply_updates = .*@apply_updates = yes@" /etc/dnf/automatic.conf

#systemctl daemon-reload
#systemctl enable --now dnf-automatic.timer

source files/system/dnf

systemctl daemon-reload
systemctl enable --now dnf-offline-automatic.timer


### flatpaks ###
# install flathub repo
flatpak --system remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# install system flatpaks
flatpak --system install flathub --assumeyes --noninteractive --or-update "${system_flatpaks[@]}"

# enable system flatpak auto-updates
source files/system/flatpak

systemctl daemon-reload
systemctl enable --now flatpak-automatic.timer


### bash ###
# configure bash prompt
source files/system/bash


### snapper ###
# configure snapper
home_mnt="$(lsblk --output MOUNTPOINTS | grep 'home$')"

if [ ! -d "$home_mnt"/.snapshots ]; then
  btrfs subvolume create "$home_mnt"/.snapshots
fi

mkdir --parents /etc/systemd/system/snapper-{cleanup.timer.d,timeline.timer.d}
mkdir --parents /etc/snapper/configs

source files/system/snapper

sed --in-place "s@^SNAPPER_CONFIGS=.*@SNAPPER_CONFIGS=\"home\"@" /etc/sysconfig/snapper

systemctl daemon-reload
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer


### vim ###
# configure vim
source files/system/vim
