#!/bin/bash
# Runs inside the image build (see Containerfile). Build inputs are mounted at /ctx.

set -ouex pipefail

# shellcheck source=/dev/null
source /usr/lib/os-release
FEDORA_VERSION="${VERSION_ID}"

### System files
# Everything under system_files/ is copied onto / as-is.
cp -avf /ctx/system_files/. /
ln -sf /usr/share/icons/hicolor/scalable/apps/iceberg-logo.svg /usr/share/pixmaps/iceberg-logo.svg

### Packages
# Anything from the Fedora or RPM Fusion repos can go here.
PACKAGES=(
    fastfetch
    btop
)
dnf5 install -y "${PACKAGES[@]}"

# COPR example. Disable it afterwards so it isn't left enabled on user systems.
# dnf5 -y copr enable owner/project
# dnf5 -y install package
# dnf5 -y copr disable owner/project

### Wallpapers
# Installed as Plasma wallpaper packages. A package with a dark image switches
# automatically with the light/dark colour scheme.
png_size() {
    od -An -tu1 -j16 -N8 "$1" | awk '{printf "%dx%d", $1*16777216+$2*65536+$3*256+$4, $5*16777216+$6*65536+$7*256+$8}'
}

install_wallpaper() {
    local id="$1" name="$2" light="/ctx/wallpaper/$3" dark="${4:+/ctx/wallpaper/$4}"
    local dest="/usr/share/wallpapers/${id}"

    install -Dm644 "${light}" "${dest}/contents/images/$(png_size "${light}").png"
    if [[ -n "${dark}" ]]; then
        install -Dm644 "${dark}" "${dest}/contents/images_dark/$(png_size "${dark}").png"
    fi
    cat >"${dest}/metadata.json" <<EOF
{
    "KPlugin": {
        "Authors": [{ "Name": "Iceberg OS" }],
        "Id": "${id}",
        "Name": "${name}"
    }
}
EOF
}

install_wallpaper Iceberg "Iceberg" light.png dark.png
install_wallpaper IcebergBlossom "Iceberg Blossom" pinkgreen.png
install_wallpaper IcebergEmber "Iceberg Ember" redpurple.png

# Plasma takes its default wallpaper from the active global theme's defaults.
# Point every installed global theme (Fedora, Breeze, Breeze Dark...) at Iceberg.
for defaults in /usr/share/plasma/look-and-feel/*/contents/defaults; do
    kwriteconfig6 --file "${defaults}" --group Wallpaper --key Image Iceberg
done

### Branding
sed -i \
    -e 's/^NAME=.*/NAME="Iceberg OS"/' \
    -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Iceberg OS ${FEDORA_VERSION} (KDE Plasma)\"/" \
    -e 's/^LOGO=.*/LOGO=iceberg-logo/' \
    -e '/^DEFAULT_HOSTNAME=/d' \
    /usr/lib/os-release
echo 'DEFAULT_HOSTNAME="iceberg"' >>/usr/lib/os-release

# System Settings > About this System
kwriteconfig6 --file /etc/xdg/kcm-about-distrorc --group General --key LogoPath /usr/share/pixmaps/iceberg-logo.svg
kwriteconfig6 --file /etc/xdg/kcm-about-distrorc --group General --key Variant "Atomic · Based on Fedora ${FEDORA_VERSION}"

### Services
systemctl enable podman.socket
