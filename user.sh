#! /usr/bin/env bash

# shellcheck disable=SC1091

### config options ###
# vars
flatpaks=(
#  'com.spotify.Client'
  'com.yubico.yubioath'
  'org.gimp.GIMP'
  'org.signal.Signal'
  'org.chromium.Chromium'
  'com.bitwarden.desktop'
  'com.visualstudio.code-oss'
)


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
flatpak --user install flathub --assumeyes --noninteractive --or-update "${flatpaks[@]}"

# enable user flatpak auto-updates
mkdir --parents "$HOME"/.config/systemd/user

tee "$HOME"/.config/systemd/user/flatpak-automatic.service > /dev/null <<EOF
[Unit]
Description=Service for flatpak-automatic
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
Restart=on-failure
RestartSec=60s

# uninstall unused flatpaks
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --user uninstall --unused --assumeyes --noninteractive --delete-data

# update
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --user update --assumeyes --noninteractive

# repair
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --user repair
EOF

tee "$HOME"/.config/systemd/user/flatpak-automatic.timer > /dev/null <<EOF
[Unit]
Description=Trigger for flatpak-automatic.service

[Timer]
OnBootSec=1h
OnUnitInactiveSec=1d
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now flatpak-automatic.timer


### gnome ###
# hide htop.desktop
tee "$HOME"/.local/share/applications/htop.desktop > /dev/null <<EOF
NoDisplay=true
EOF

# hide syncthing-start.desktop
tee "$HOME"/.local/share/applications/syncthing-start.desktop > /dev/null <<EOF
NoDisplay=true
EOF


