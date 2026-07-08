# Blue Reboot

Blue Reboot is a bootc OS image derived from [Fedora
Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/).

## About

Blue Reboot makes the following changes to the upstream image:

- Replace the Fedora Flatpak remote with the Flathub remote.
- Make Flatpak the default package source over RPM in GNOME Software.
- Replace the Firefox RPM package with the Flatpak.
- Provide a different set of default Flatpak apps.
  - Loupe (Image Viewer)
  - Papers (Document Viewer)
  - Showtime (Video Player)
  - Decibels (Audio Player)
  - Snapshot (Camera)
  - Clocks
  - Text Editor
  - Calculator

This image is inspired by the [Universal Blue](https://universal-blue.org/)
base images, but sticks closer to the upstream Fedora Atomic project.

## Install

You can download the installation `.iso` here:

[blue-reboot.iso](https://bootc-images.lark.gay/blue-reboot.iso)

## Rebase

These are instructions for rebasing an existing Fedora Atomic installation to
the latest build.

First rebase to the unsigned image, to get the proper signing keys and policies
installed:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/justlark/blue-reboot:latest
```

Reboot to complete the rebase:

```bash
systemctl reboot
```

Then rebase to the signed image, like so:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/justlark/blue-reboot:latest
```

Reboot again to complete the installation

```bash
systemctl reboot
```

## Build

Install [just](https://just.systems/man/en/installation.html) and run `just` in
the repo to see a list of recipes.

## Verify

Blue Reboot images are signed with [Sigstore](https://www.sigstore.dev/)'s
[cosign](https://github.com/sigstore/cosign). You can verify the signature by
downloading the [cosign.pub](./cosign.pub) file from this repo and running the
following command:

```bash
cosign verify --key cosign.pub ghcr.io/justlark/blue-reboot:latest
```
