set shell := ["nu", "-c"]

repo_org := "justlark"
repo_name := "blue-reboot"
image_name := "blue-reboot"
default_tag := "latest"
base_image := "quay.io/fedora/fedora-silverblue"
base_tag := "latest"
image_title := "Blue Reboot"
image_desc := "A bootc OS image which tweaks Fedora Silverblue"
git_rev_long := `git rev-parse HEAD`
git_rev_short := `git rev-parse --short=8 HEAD`
datetime := `date now | date to-timezone UTC | format date "%Y-%m-%dT%H:%M:%SZ"`

[private]
default:
    @just --list

# build a container image locally using podman
build-image:
    #!/usr/bin/env nu

    let metadata = {
      "org.opencontainers.image.title": "{{ image_title }}",
      "org.opencontainers.image.description": "{{ image_desc }}",
      "org.opencontainers.image.documentation": "https://raw.githubusercontent.com/{{ repo_org }}/{{ repo_name }}/{{ git_rev_long }}/README.md",
      "org.opencontainers.image.url": "https://github.com/{{ repo_org }}/{{ repo_name }}/tree/{{ git_rev_long }}",
      "org.opencontainers.image.source": "https://github.com/{{ repo_org }}/{{ repo_name }}",
      "org.opencontainers.image.version": (podman run --rm quay.io/skopeo/stable:latest inspect docker://{{ base_image }}:{{ base_tag }} | from json | get "Labels" | get "org.opencontainers.image.version"),
      "org.opencontainers.image.revision": "{{ git_rev_long }}",
      "org.opencontainers.image.created": "{{ datetime }}",
      "org.opencontainers.image.base.name": "{{ base_image }}:{{ base_tag }}",
    }

    let flags = (
      $metadata
        | items {|key, value| ["--annotation" $"($key)=($value)" "--label" $"($key)=($value)"] }
        | flatten
    )

    ./scripts/exec.nu sudo podman build ...$flags --pull=newer --tag "{{ image_name }}:{{ default_tag }}" --file Containerfile .

# build an ISO image from the container image
build-iso:
    #!/usr/bin/env nu

    mkdir ./output/

    ./scripts/exec.nu sudo podman run --rm --privileged --pull=newer --net=host --security-opt label=type:unconfined_t --volume $"(pwd)/config/iso.toml:/config.toml:ro" --volume $"(pwd)/output/:/output" --volume /var/lib/containers/storage:/var/lib/containers/storage quay.io/centos-bootc/bootc-image-builder:latest --type iso --use-librepo=True --rootfs=btrfs "localhost/{{ image_name }}:{{ default_tag }}"

    ./scripts/exec.nu sudo chown --recursive $"(whoami):(whoami)" ./output/

# tag the container image for pushing to the container registry
tag-image:
    #!/usr/bin/env nu

    let version = ./scripts/exec.nu sudo podman inspect "localhost/{{ image_name }}:{{ default_tag }}" | from json | get 0 | get "Labels" | get "org.opencontainers.image.version"

    ./scripts/exec.nu sudo podman tag "{{ image_name }}:{{ default_tag }}" "ghcr.io/{{ repo_org }}/{{ image_name }}:{{ default_tag }}"
    ./scripts/exec.nu sudo podman tag "{{ image_name }}:{{ default_tag }}" "ghcr.io/{{ repo_org }}/{{ image_name }}:{{ git_rev_short }}"
    ./scripts/exec.nu sudo podman tag "{{ image_name }}:{{ default_tag }}" $"ghcr.io/{{ repo_org }}/{{ image_name }}:($version)"

# push the container image to the container registry
push-image:
    #!/usr/bin/env nu

    mkdir ./output/

    let version = ./scripts/exec.nu sudo podman inspect "localhost/{{ image_name }}:{{ default_tag }}" | from json | get 0 | get "Labels" | get "org.opencontainers.image.version"

    ./scripts/exec.nu sudo podman push --digestfile ./output/digest "ghcr.io/{{ repo_org }}/{{ image_name }}:{{ default_tag }}"
    ./scripts/exec.nu sudo podman push "ghcr.io/{{ repo_org }}/{{ image_name }}:{{ git_rev_short }}"
    ./scripts/exec.nu sudo podman push  $"ghcr.io/{{ repo_org }}/{{ image_name }}:($version)"
