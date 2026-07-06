# Allow build scripts to be referenced without being copied into the final
# image.
FROM scratch AS ctx
COPY build /
COPY system /system

# Base image.
FROM quay.io/fedora/fedora-silverblue:latest

# The base image has `/opt` symlinked to `/var/opt`, in order to make it
# writable by users. However, some packages write files to this directory. We
# make `/opt` immutable by removing the symlink and creating a new directory.
# This will allow packages to write to `/opt` without losing their files.
RUN rm /opt && mkdir /opt

# Most modifications live in this script.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

# Verify final image and contents are correct.
RUN bootc container lint
