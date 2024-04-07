#! /usr/bin/env bash

# shellcheck disable=SC1091

### config options ###
# vars
flatpaks=(
  'com.github.tchx84.Flatseal'
  'com.spotify.Client'
  'com.yubico.yubioath'
  'org.gimp.GIMP'
  'org.signal.Signal'
  'org.chromium.Chromium'
  'com.bitwarden.desktop'
  'com.visualstudio.code-oss'
  'org.gnome.Geary'
)


### disclaimer ###
if [[ "$EUID" = "0" ]]; then
    echo "Please run as user, exiting..."
    sleep 2
    exit
fi


### flatpaks ###
# instal flathub repo
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# install user flatpaks
flatpak --user install flathub --assumeyes --noninteractive "${flatpaks[@]}"

# enable user flatpak auto-updates
mkdir --parents "$HOME"/.config/systemd/user

tee "$HOME"/.config/systemd/user/flatpak-automatic.service > /dev/null <<EOF
[Unit]
Description=Service for flatpak-automatic
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
# https://github.com/ublue-os/config/issues/168
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --user uninstall --unused --assumeyes --noninteractive --delete-data
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --user update -assumeyes --noninteractive
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --user repair
Restart=on-failure
RestartSec=60s
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