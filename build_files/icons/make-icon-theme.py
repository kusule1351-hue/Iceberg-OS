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
        "plate_top": "#FFFFFF",
        "plate_bottom": "#EEEEF1",
        "edge": "#000000",
        "edge_opacity": "0.08",
        "shadow_opacity": "0.10",
    },
    "Iceberg-Dark": {
        "inherits": "breeze-dark,hicolor",
        "plate_top": "#3A3A3F",
        "plate_bottom": "#28282C",
        "edge": "#FFFFFF",
        "edge_opacity": "0.10",
        "shadow_opacity": "0.35",
    },
}

PLATE = """<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="64" height="64" viewBox="0 0 64 64">
  <defs>
    <linearGradient id="iceberg-plate" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{plate_top}"/>
      <stop offset="1" stop-color="{plate_bottom}"/>
    </linearGradient>
  </defs>
  <rect x="4" y="5.5" width="56" height="56" rx="14" fill="#000000" opacity="{shadow_opacity}"/>
  <rect x="4" y="4" width="56" height="56" rx="14" fill="url(#iceberg-plate)"/>
  <rect x="4.5" y="4.5" width="55" height="55" rx="13.5" fill="none" stroke="{edge}" stroke-opacity="{edge_opacity}"/>
  <image x="12" y="12" width="40" height="40" xlink:href="data:image/png;base64,{glyph}"/>
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
