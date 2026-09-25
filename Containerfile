# Iceberg OS: a Fedora Kinoite (KDE Plasma) based bootc image.

# Fedora release to build on. Bump this when a new Fedora ships (45 is due October 2026).
ARG FEDORA_VERSION=44

# Universal Blue's Kinoite image: stock Fedora Kinoite plus media codecs,
# RPM Fusion and hardware enablement. For a 100% stock Fedora base, use
# quay.io/fedora/fedora-kinoite instead.
ARG BASE_IMAGE=ghcr.io/ublue-os/kinoite-main

# Build inputs are mounted from this stage so they don't end up in the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files
COPY wallpaper /wallpaper

FROM ${BASE_IMAGE}:${FEDORA_VERSION}

### [IM]MUTABLE /opt
## Fedora symlinks /opt to /var/opt so users can write to it, but packages that
## install into /opt (e.g. google-chrome) can then lose files on deployment.
## Uncomment to make /opt part of the immutable image instead.
# RUN rm /opt && mkdir /opt

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    bash /ctx/build.sh

RUN bootc container lint
