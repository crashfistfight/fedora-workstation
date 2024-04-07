#! /usr/bin/env bash

# shellcheck disable=SC2154

### config options ###
# vars
packages=(
  'htop'
  'snapper'
  'vim'
  'syncthing'
  'dnf-automatic'
  'nautilus'
  'gnome-console'
  'virt-manager'
  'borgmatic'
  )

removals=(
  'gnome-boxes'
  'gnome-clocks'
  'gnome-characters'
  'gnome-contacts'
  'gnome-connections'
  'gnome-font-viewer'
  'gnome-software'
  'gnome-logs'
  'gnome-calendar'
  'gnome-maps'
  'gnome-tour'
  'yelp'
  'gnome-weather'
  'gnome-text-editor'
  'totem*'
  'libreoffice*'
  'rhythmbox'
  'cheese'
  'simple-scan'
  'evince*'
  'loupe'
  'gnome-calculator'
  'baobab'
  'mediawriter'
  'firefox'
  'firefox-langpacks'
  'gnome-terminal'
)

flatpaks=(
  'org.gnome.baobab'
  'org.gnome.TextEditor'
  'org.gnome.Evince'
  'org.gnome.Calendar'
  'org.gnome.Contacts'
  'org.gnome.Logs'
  'org.gnome.Loupe'
  'org.gnome.Snapshot'
  'org.gnome.Calculator'
  'org.mozilla.firefox'
  'org.freedesktop.Platform.ffmpeg-full/x86_64/23.08'
  'org.gnome.Firmware'
)


### disclaimer ###
if [[ ! "$EUID" = "0" ]]; then
    echo "Please run as root, exiting..."
    sleep 2
    exit
fi


### dnf ###
# remove, update and install packages
dnf autoremove --assumeyes "${removals[@]}"
dnf update --assumeyes
dnf install --assumeyes "${packages[@]}"

# configure system updates
sed --in-place "s@^apply_updates = .*@apply_updates = yes@" /etc/dnf/automatic.conf

systemctl daemon-reload
systemctl enable --now dnf-automatic.timer


### flatpaks ###
# install flathub repo
flatpak --system remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# install system flatpaks
flatpak --system install flathub --assumeyes --noninteractive "${flatpaks[@]}"

# enable system flatpak auto-updates
tee /etc/systemd/system/flatpak-automatic.service > /dev/null <<EOF
[Unit]
Description=Service for flatpak-automatic
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
# https://github.com/ublue-os/config/issues/168
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --system uninstall --unused --assumeyes --noninteractive --delete-data
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --system update -assumeyes --noninteractive
ExecStart=/usr/bin/dbus-run-session /usr/bin/flatpak --system repair
Restart=on-failure
RestartSec=60s
EOF

tee /etc/systemd/system/flatpak-automatic.timer > /dev/null <<EOF
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

systemctl daemon-reload
systemctl enable --now flatpak-automatic.timer


### bash ###
# configure bash prompt
tee /etc/profile.d/prompt.sh > /dev/null <<EOF
#! /usr/bin/env bash

export PS1="[\[\e[31m\]\u\[\e[m\]@\h] \[\e[01;31m\]:\[\e[m\]\[\e[01;31m\]:\[\e[m\] \W \[\e[01;31m\]>\[\e[m\] "
EOF


### snapper ###
# configure snapper
mkdir --parents /etc/systemd/system/snapper-{cleanup.timer.d,timeline.timer.d}
mkdir --parents /etc/snapper/configs

  tee /etc/systemd/system/snapper-cleanup.timer.d/override.conf > /dev/null <<EOF
[Timer]
OnBootSec=
OnUnitActiveSec=
OnCalendar=hourly
Persistent=true
EOF

tee /etc/systemd/system/snapper-timeline.timer.d/override.conf > /dev/null <<EOF
[Timer]
Persistent=true
EOF

tee /etc/snapper/configs/home > /dev/null <<EOF
# subvolume to snapshot
SUBVOLUME="$(lsblk --output MOUNTPOINTS | grep 'home$')"

# filesystem type
FSTYPE="btrfs"

# create hourly snapshots
TIMELINE_CREATE="yes"

# cleanup hourly snapshots after some time
TIMELINE_CLEANUP="yes"

# limits for timeline cleanup
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="24"
TIMELINE_LIMIT_DAILY="3"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"

# cleanup empty pre-post-pairs
EMPTY_PRE_POST_CLEANUP="yes"
EOF

sed --in-place "s@^SNAPPER_CONFIGS=.*@SNAPPER_CONFIGS=\"home\"@" /etc/sysconfig/snapper

systemctl daemon-reload
systemctl enable --now snapper-timeline.timer snapper-cleanup.service


### vim ###
# configure vim
tee /etc/vimrc > /dev/null <<EOF
set autoindent
set autoread
set autowrite
set expandtab
set hidden
set ignorecase
set incsearch
set laststatus=2
set linebreak
set list listchars=tab:▸\ ,trail:·
set nofoldenable
set nojoinspaces
set number
set path+=**
set printoptions=paper:A4,syntax:n,number:y
set shiftwidth=4
set showbreak=↪\
set splitbelow
set splitright
set statusline=\(%n\)\ %<%.99f\ %y\ %w%m%r%=%-14.(%l,%c%V%)\ %P
set tabstop=4
set textwidth=120
set wrapscan
EOF


### gnome ###
# hide htop
mv /usr/share/applications/{htop.desktop,htop.desktop.hide}

# hide start-syncthing
mv /usr/share/applications/{syncthing-start.desktop,syncthing-start.desktop.hide}

# global gsettings
tee /etc/dconf/db/local.d/01-custom > /dev/null <<EOF
[org/gnome/desktop/interface]
show-battery-percentage='true'

[org/gnome/desktop/peripherals/touchpad]
tap-to-click='true'
two-finger-scrolling-enabled='true'
natural-scroll='true'

[org/gnome/desktop/privacy]
disable-microphone='true'

[org/gnome/desktop/wm/keybindings]
close=['<Super>q']

[org/gnome/settings-deaemon/plugins/color]
night-light-enabled='true'
night-light-temperature='2159'

[org/gnome/desktop/app-folders]
folder-children=['']
EOF

dconf update