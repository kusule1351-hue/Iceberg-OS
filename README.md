# Iceberg OS

An atomic Linux desktop built on **Fedora Kinoite** (Fedora's KDE Plasma image) using [bootc](https://bootc-dev.github.io/bootc/).

The whole OS is defined as a container image. GitHub Actions builds it every day on top of the latest Fedora updates and publishes it to GitHub Container Registry (GHCR). Installed machines download updates as a single unit and can roll back to the previous version if something breaks.

- **Base:** `ghcr.io/ublue-os/kinoite-main:44`: Fedora Kinoite 44 with media codecs and RPM Fusion added by Universal Blue
- **Desktop:** KDE Plasma
- **Branding:** Iceberg name, logo and wallpapers. The default Iceberg wallpaper switches between light and dark along with the colour scheme.

## Repository layout

| Path | What it does |
| --- | --- |
| `Containerfile` | Picks the base image and Fedora version, then runs the build script |
| `build_files/build.sh` | Installs packages, wallpapers and branding. **Most customisation happens here.** |
| `system_files/` | Copied onto `/` as-is. Put config files here (e.g. `system_files/etc/...`). |
| `wallpaper/` | Source wallpapers, installed as Plasma wallpaper packages |
| `disk_config/` | Settings for the installer ISO and VM images |
| `image.env` | Image name and metadata |
| `.github/workflows/build.yml` | Builds the OS image and publishes it to GHCR (on push, daily and manually) |
| `.github/workflows/build-disk.yml` | Builds the installer ISO from the published image (manual) |

## Getting started

Your PC doesn't need Linux; GitHub runs the builds.

1. Create an **empty** GitHub repository named `iceberg-os`.
2. In `image.env`, set `REPO_ORGANIZATION` to your GitHub username.
3. Push this folder:
   ```bash
   git add -A
   git commit -m "Initial Iceberg OS"
   git remote add origin https://github.com/<you>/iceberg-os.git
   git push -u origin main
   ```
4. Open the **Actions** tab and wait for **Build container image** to finish (about 15–25 minutes).
5. Make the image public. Go to your GitHub profile → **Packages** → `iceberg-os` → **Package settings** → **Change visibility** → Public. Installed systems download updates from here anonymously, so this is required.
6. Run **Actions → Build disk images → Run workflow**. When it finishes, download `iceberg-os-anaconda-iso` from the run's artifacts. That's your installer.

## Installing

- **From the ISO:** write it to a USB stick (e.g. with Fedora Media Writer or Ventoy) and boot from it.
- **From an existing Fedora Atomic system** (Kinoite, Silverblue, Bazzite…):
  ```bash
  sudo bootc switch ghcr.io/<you>/iceberg-os:latest
  ```
  Then reboot.

To update, run `sudo bootc upgrade` and reboot, or use Discover. To go back to the previous version, run `sudo bootc rollback`.

## Customising

- **Packages:** add to the `PACKAGES` list in `build_files/build.sh`.
- **Fedora version:** change `FEDORA_VERSION` in `Containerfile`.
- **Wallpapers:** add the image to `wallpaper/` and add an `install_wallpaper` line in `build.sh`.
- **Desktop look:** Iceberg Light and Iceberg Dark are global themes in `system_files/usr/share/plasma/look-and-feel/`. Their colours are in `system_files/usr/share/color-schemes/`. The dock is defined in `build_files/plasma/`: `dock-layout.js` sets which items it holds, and `dock-style.json` sets how the tiles look. Plasma switches between light and dark at sunrise and sunset.
- **Seeing a new look on an existing install:** after updating, go to System Settings → Colors & Themes → Global Theme, pick Iceberg Light or Iceberg Dark, tick "Desktop and window layout", then Apply. New user accounts get the look automatically.
- **Pure Fedora base:** set `BASE_IMAGE=quay.io/fedora/fedora-kinoite` in `Containerfile`. You lose the extra codecs.

Every push to `main` builds a new image. Pull requests run the build without publishing it, so you can test changes safely.

## Image signing (optional)

Signing lets installed systems check that updates really came from you. To set it up, run this on any Linux machine or in WSL:

```bash
cosign generate-key-pair
```

Add the contents of `cosign.key` as a repository secret named `SIGNING_SECRET`, and commit `cosign.pub`. **Never commit `cosign.key`.** Signing is skipped until that secret exists.

## Building locally (Linux only)

Requires `podman` and [`just`](https://github.com/casey/just):

```bash
just build        # build the image
just build-qcow2  # make a VM disk image from it
just run-vm-qcow2 # boot that disk in a browser-based VM
```

## Known limitations

- The login screen can't be branded. Fedora 44 uses Plasma Login Manager, which only supports the stock Breeze theme.
- The wallpapers are 1672×941, so they will look soft on 1440p and 4K screens. Replace them with higher-resolution versions if you have them.

Based on the [Universal Blue image template](https://github.com/ublue-os/image-template).
