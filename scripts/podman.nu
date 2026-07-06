#!/usr/bin/env nu

# This script supports running podman commands from inside a distrobox
# container, because the maintainer of this project uses distrobox as their
# development environment.
def --wrapped main [...args] {
  if ("CONTAINER_ID" in $env) {
    exec distrobox-host-exec sudo podman ...$args
  } else {
    exec sudo podman ...$args
  }
}
