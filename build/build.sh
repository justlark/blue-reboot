#!/usr/bin/env bash

set -ouex pipefail

# Copy into the filesystem.
cp --archive --verbose --force /ctx/system/. /

# Starting with Fedora 45, `fedora-repos` installs its repo files to
# `/usr/share/dnf5/repos.d/` instead of `/etc/yum.repos.d/`. dnf5 reads both,
# but bootc-image-builder only looks in `/etc/yum.repos.d/` when resolving the
# installer packages for the ISO, so it fails with "There are no enabled
# repositories". Link the repo files back into `/etc/yum.repos.d/`. The links
# are relative so they resolve correctly when the image root is mounted
# somewhere other than `/`, and a file in `/etc/yum.repos.d/` overrides the
# one with the same name in `/usr/share/dnf5/repos.d/`, so no repo is
# duplicated.
mkdir --parents /etc/yum.repos.d/
for repo_file in /usr/share/dnf5/repos.d/*.repo; do
  [[ -e "$repo_file" ]] || continue
  link_path="/etc/yum.repos.d/$(basename "$repo_file")"
  [[ -e "$link_path" || -L "$link_path" ]] && continue
  ln --symbolic "../../usr/share/dnf5/repos.d/$(basename "$repo_file")" "$link_path"
done

# Remove packages from the base image.
dnf5 --assumeyes remove fedora-flathub-remote fedora-third-party firefox firefox-langpacks 

# Add the Flathub flatpakref to the image.
mkdir --parents /etc/flatpak/remotes.d/
curl --retry 3 --location --output /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# Fedora ships with a service which adds the Fedora Flatpak remote on boot. We
# replace it with one that adds the Flathub remote instead.
rm --force /usr/lib/systemd/system/flatpak-add-fedora-repos.service

# On first boot, replace the Fedora Flatpak remote with the Flathub remote and
# install default flatpaks.
systemctl enable flatpak-add-flathub-repos.service flatpak-preinstall.service
