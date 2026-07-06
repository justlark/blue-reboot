#!/usr/bin/env nu

# This script allows for running commands on the host from inside a distrobox
# container, because the maintainer of this project uses distrobox as their
# development environment.
def --wrapped main [command: string, ...args] {
  if ("CONTAINER_ID" in $env) {
    exec distrobox-host-exec $command ...$args
  } else {
    exec $command ...$args
  }
}
