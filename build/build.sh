#!/usr/bin/env bash

set -ouex pipefail

# Copy into the filesystem.
cp --archive --verbose --force /ctx/system/. /

# Remove packages from the base image.
dnf5 --assumeyes remove fedora-flathub-remote fedora-third-party gnome-software-rpm-ostree firefox firefox-langpacks 

# Add the Flathub flatpakref to the image.
mkdir --parents /etc/flatpak/remotes.d/
curl --retry 3 --location --output /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# Fedora ships with a service which adds the Fedora Flatpak remote on boot. We
# replace it with one that adds the Flathub remote instead.
rm --force /usr/lib/systemd/system/flatpak-add-fedora-repos.service

# On first boot, replace the Fedora Flatpak remote with the Flathub remote and
# install default flatpaks.
systemctl enable flatpak-add-flathub-repos.service flatpak-preinstall.service
