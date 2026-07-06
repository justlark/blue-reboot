set shell := ["nu", "-c"]

repo_org := "justlark"
repo_name := "blue-reboot"
image_name := "blue-reboot"
default_tag := "latest"
base_image := "quay.io/fedora/fedora-silverblue"
base_tag := "latest"
image_title := "Blue Reboot"
image_desc := "A bootc OS image which tweaks Fedora Silverblue"
git_rev := `git rev-parse --short=8 HEAD`
datetime := `date now | date to-timezone UTC | format date "%Y-%m-%dT%H:%M:%SZ"`
pwd := `pwd`
user := `whoami`

[private]
default:
    @just --list

# build a container image locally using podman
build-image:
    ./scripts/exec.nu sudo podman build \
      --label "org.opencontainers.image.title={{ image_title }}" \
      --label "org.opencontainers.image.description={{ image_desc }}" \
      --label "org.opencontainers.image.documentation=https://raw.githubusercontent.com/{{ repo_org }}/{{ repo_name }}/{{ git_rev }}/README.md" \
      --label "org.opencontainers.image.url=https://github.com/{{ repo_org }}/{{ repo_name }}/tree/{{ git_rev }}" \
      --label "org.opencontainers.image.source=https://github.com/{{ repo_org }}/{{ repo_name }}/blob/{{ git_rev }}/Containerfile" \
      --label "org.opencontainers.image.revision={{ git_rev }}" \
      --label "org.opencontainers.image.created={{ datetime }}" \
      --label "org.opencontainers.image.base.name={{ base_image }}:{{ base_tag }}" \
      --pull=newer \
      --tag "{{ image_name }}:{{ default_tag }}" \
      --file Containerfile \
      .

# convert a container image to a bootc ISO image
build-iso:
    mkdir ./output/

    ./scripts/exec.nu sudo podman run \
      --rm \
      --interactive \
      --tty \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      --volume "{{ pwd }}/config/iso.toml:/config.toml:ro" \
      --volume "{{ pwd }}/output/:/output" \
      --volume /var/lib/containers/storage:/var/lib/containers/storage \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type iso \
      --use-librepo=True \
      --rootfs=btrfs \
      "{{ image_name }}:{{ default_tag }}"

    ./scripts/exec.nu sudo chown --recursive "{{ user }}:{{ user }}" ./output/

# build a bootc ISO image
build: build-image build-iso

# tag the container image for pushing to the container registry
tag-image:
    ./scripts/exec.nu podman tag "{{ image_name }}:{{ default_tag }}" "ghcr.io/{{ repo_org }}/{{ image_name }}:{{ default_tag }}"
    ./scripts/exec.nu podman tag "{{ image_name }}:{{ default_tag }}" "ghcr.io/{{ repo_org }}/{{ image_name }}:{{ git_rev }}"

# push the container image to the container registry
push-image:
    ./scripts/exec.nu sudo podman push "ghcr.io/{{ repo_org }}/{{ image_name }}:{{ default_tag }}"
    ./scripts/exec.nu sudo podman push --digestfile ./output/digest "ghcr.io/{{ repo_org }}/{{ image_name }}:{{ git_rev }}"
