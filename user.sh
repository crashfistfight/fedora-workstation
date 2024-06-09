#! /usr/bin/env bash

# shellcheck disable=SC1091,SC2154

### config options ###
# vars
source vars/all


### tests ###
if [[ "$EUID" = "0" ]]; then
    echo "Please run as user, exiting..."
    sleep 2
    exit
fi


### flatpaks ###
# instal flathub repo
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# install user flatpaks
flatpak --user install flathub --assumeyes --noninteractive --or-update "${user_flatpaks[@]}"

# enable user flatpak auto-updates
mkdir --parents "$HOME"/.config/systemd/user

source files/user/flatpak

systemctl --user daemon-reload
systemctl --user enable --now flatpak-automatic.timer


### gnome ###
# hide app icons
source files/user/hide-app-icons