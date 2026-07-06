set shell := ["nu", "-c"]

repo_org := "justlark"
repo_name := "blue-reboot"
image_name := "blue-reboot"
local_image_name := "localhost/" + image_name
default_tag := "latest"
base_image := "quay.io/fedora/fedora-silverblue"
base_tag := "latest"
image_title := "Blue Reboot"
image_desc := "A bootc OS image which tweaks Fedora Silverblue"
git_rev := `git rev-parse --short=8 HEAD`
datetime := `date now | date to-timezone UTC | format date "%Y-%m-%dT%H:%M:%SZ"`

[private]
default:
    @just --list

# build a container image locally using podman
build-image $tag=default_tag:
    podman build \
      --label "org.opencontainers.image.title={{ image_title }}" \
      --label "org.opencontainers.image.description={{ image_desc }}" \
      --label "org.opencontainers.image.documentation=https://raw.githubusercontent.com/{{ repo_org }}/{{ repo_name }}/{{ git_rev }}/README.md" \
      --label "org.opencontainers.image.url=https://github.com/{{ repo_org }}/{{ repo_name }}/tree/{{ git_rev }}" \
      --label "org.opencontainers.image.source=https://github.com/{{ repo_org }}/{{ repo_name }}/blob/{{ git_rev }}/Containerfile" \
      --label "org.opencontainers.image.revision={{ git_rev }}" \
      --label "org.opencontainers.image.created={{ datetime }}" \
      --label "org.opencontainers.image.base.name={{ base_image }}:{{ base_tag }}" \
      --pull=newer \
      --tag "{{ image_name }}:{{ tag }}" \
      --file Containerfile \
      .

# convert a container image to a bootc ISO image
build-iso $target_image=local_image_name $tag=default_tag:
    let tmp_dir = (mktemp --directory)

    sudo podman run \
      --rm \
      --interactive \
      --tty \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      --volume $"(pwd)/config/iso.toml:/config.toml:ro" \
      --volume $"($tmp_dir):/output" \
      --volume /var/lib/containers/storage:/var/lib/containers/storage \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type iso \
      --use-librepo=True \
      --rootfs=btrfs \
      "{{ target_image }}:{{ tag }}"

    mkdir --parents ./output/
    sudo mv -f $tmp_dir/* ./output/
    sudo rmdir $tmp_dir
    sudo chown --recursive $"($env.USER):($env.USER)" ./output/

# build a bootc ISO image
build target_image="localhost/{{ image_tag }}" tag="{{ default_tag }}": (build-image tag) (build-iso target_image tag)
