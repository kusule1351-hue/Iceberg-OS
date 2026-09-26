#!/usr/bin/env python3
"""Build the Iceberg icon themes.

Every installed app keeps its own icon (from Breeze or the app itself), placed
on an Iceberg rounded-square plate: white for Iceberg, graphite for Iceberg-Dark.
Everything else (folders, actions, status icons) is inherited from Breeze.
"""
import base64
import configparser
import glob
import os
import subprocess

SEARCH_DIRS = [
    "/usr/share/icons/breeze/apps/48",
    "/usr/share/icons/hicolor/scalable/apps",
    "/usr/share/icons/hicolor/512x512/apps",
    "/usr/share/icons/hicolor/256x256/apps",
    "/usr/share/icons/hicolor/128x128/apps",
    "/usr/share/icons/hicolor/96x96/apps",
    "/usr/share/icons/hicolor/64x64/apps",
    "/usr/share/icons/hicolor/48x48/apps",
    "/usr/share/pixmaps",
]
EXTENSIONS = (".svg", ".svgz", ".png")
GLYPH_PX = 192  # raster size of the app's own icon inside the plate

THEMES = {
    "Iceberg": {
        "inherits": "breeze,hicolor",
        "plate": "#FFFFFF",
        "edge": "#000000",
        "edge_opacity": "0.08",
    },
    "Iceberg-Dark": {
        "inherits": "breeze-dark,hicolor",
        "plate": "#3A3A40",
        "edge": "#FFFFFF",
        "edge_opacity": "0.09",
    },
}

# A flat plate filling the whole icon, a hairline edge, and the app's glyph at 70%
PLATE = """<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64">
  <rect x="0" y="0" width="64" height="64" rx="18" fill="{plate}"/>
  <rect x="0.5" y="0.5" width="63" height="63" rx="17.5" fill="none" stroke="{edge}" stroke-opacity="{edge_opacity}"/>
  <image x="9.5" y="9.5" width="45" height="45" xlink:href="data:image/png;base64,{glyph}"/>
</svg>
"""


def find_icon(name):
    for directory in SEARCH_DIRS:
        for ext in EXTENSIONS:
            path = os.path.join(directory, name + ext)
            if os.path.exists(path):
                return path
    return None


def glyph_png(path):
    if path.endswith(".png"):
        with open(path, "rb") as f:
            return f.read()
    return subprocess.run(
        ["rsvg-convert", "-w", str(GLYPH_PX), "-h", str(GLYPH_PX), "--keep-aspect-ratio", path],
        check=True, capture_output=True,
    ).stdout


def app_icon_names():
    names = set()
    for desktop in glob.glob("/usr/share/applications/*.desktop"):
        parser = configparser.ConfigParser(interpolation=None, strict=False)
        try:
            parser.read(desktop, encoding="utf-8")
            icon = parser.get("Desktop Entry", "Icon", fallback="").strip()
        except (configparser.Error, UnicodeDecodeError):
            continue
        if icon and "/" not in icon:
            names.add(icon)
    return sorted(names)


def write_index(theme_dir, name, inherits):
    with open(os.path.join(theme_dir, "index.theme"), "w") as f:
        f.write(f"""[Icon Theme]
Name={name}
Comment=Iceberg OS app icons on rounded plates
Inherits={inherits}
Directories=apps/scalable

[apps/scalable]
Size=64
MinSize=16
MaxSize=512
Type=Scalable
Context=Applications
""")


def main():
    glyphs = {}
    for name in app_icon_names():
        path = find_icon(name)
        if not path:
            print(f"no icon found for {name}, leaving it to Breeze")
            continue
        try:
            glyphs[name] = base64.b64encode(glyph_png(path)).decode()
        except subprocess.CalledProcessError as error:
            print(f"could not render {path}: {error.stderr.decode().strip()}")

    for theme, style in THEMES.items():
        theme_dir = f"/usr/share/icons/{theme}"
        apps_dir = os.path.join(theme_dir, "apps", "scalable")
        os.makedirs(apps_dir, exist_ok=True)
        for name, glyph in glyphs.items():
            with open(os.path.join(apps_dir, name + ".svg"), "w") as f:
                f.write(PLATE.format(glyph=glyph, **style))
        write_index(theme_dir, theme, style["inherits"])
        print(f"{theme}: {len(glyphs)} app icons")


if __name__ == "__main__":
    main()
