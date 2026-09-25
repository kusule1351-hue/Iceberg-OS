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
    firefox
    rsms-inter-fonts
)
dnf5 install -y "${PACKAGES[@]}"

# Panel Colorizer draws the Iceberg dock's rounded tiles. It's packaged by its
# author on the openSUSE Build Service; the repo is removed again afterwards so
# the package only updates when the image is rebuilt.
curl -fsSLo /etc/yum.repos.d/panel-colorizer.repo \
    "https://download.opensuse.org/repositories/home:/luisbocanegra/Fedora_${FEDORA_VERSION}/home:luisbocanegra.repo"
dnf5 install -y plasma-panel-colorizer
rm -f /etc/yum.repos.d/panel-colorizer.repo

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

### Iceberg desktop
# Two global themes, Iceberg Light and Iceberg Dark (system_files/usr/share/plasma/look-and-feel),
# share one dock layout. Plasma switches between them automatically at sunrise and sunset.
python3 - <<'EOF'
import json, os

# Pinned dock apps, in order. The first browser that exists wins.
browser = next((b for b in ("firefox", "org.mozilla.firefox")
                if os.path.exists(f"/usr/share/applications/{b}.desktop")), None)
apps = [browser, "org.kde.dolphin", "org.kde.konsole", "org.kde.discover", "systemsettings"]
launchers = [f"applications:{a}.desktop" for a in apps
             if a and os.path.exists(f"/usr/share/applications/{a}.desktop")]
print("Dock launchers:", launchers)

with open("/ctx/plasma/dock-style.json") as f:
    style = json.load(f)
with open("/ctx/plasma/dock-layout.js") as f:
    layout = f.read().replace("@LAUNCHERS@", json.dumps(launchers)).replace("@DOCK_STYLE@", json.dumps(style))

for theme in ("light", "dark"):
    path = f"/usr/share/plasma/look-and-feel/org.icebergos.{theme}.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(layout)

# Also offer the tile style as a Panel Colorizer preset, so it can be re-applied by hand.
preset = "/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/Iceberg"
os.makedirs(preset, exist_ok=True)
with open(f"{preset}/settings.json", "w") as f:
    json.dump({"globalSettings": style}, f, indent=4)
EOF

install -Dm644 /ctx/wallpaper/light.png /usr/share/plasma/look-and-feel/org.icebergos.light.desktop/contents/previews/preview.png
install -Dm644 /ctx/wallpaper/dark.png /usr/share/plasma/look-and-feel/org.icebergos.dark.desktop/contents/previews/preview.png

# Make Iceberg the default global theme, including anywhere Fedora sets its own.
grep -rn -e '^LookAndFeelPackage=' -e '^ColorScheme=' /etc/xdg /usr/share/kde-settings 2>/dev/null || true
for config in $(grep -rl '^LookAndFeelPackage=' /etc/xdg /usr/share/kde-settings 2>/dev/null); do
    sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.icebergos.light.desktop/' "${config}"
done
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage org.icebergos.light.desktop
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key DefaultLightLookAndFeel org.icebergos.light.desktop
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key DefaultDarkLookAndFeel org.icebergos.dark.desktop
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key AutomaticLookAndFeel --type bool true
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key ColorScheme IcebergLight

# Inter as the interface font, with semibold window titles
fc-list : family | grep -i inter || true
INTER="Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key font "${INTER}"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key menuFont "${INTER}"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key toolBarFont "${INTER}"
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key smallestReadableFont "Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file /etc/xdg/kdeglobals --group WM --key activeFont "Inter,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1"

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
