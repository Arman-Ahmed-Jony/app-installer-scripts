Perfect. Here's a clean and robust Linux app installer script that supports:

✅ **APT**, **Flatpak**, **Snap**, and **custom `.deb` URLs**
✅ **Checks if the app is already installed** before installing
✅ **Uses separate list files** (optional) for easy customization

---

## 🧰 Final Script: `install-apps.sh`

```bash
#!/bin/bash

set -e  # Stop on error

# Directories
DEB_DIR="./deb-packages"
APT_LIST="./apt-apps.txt"
SNAP_LIST="./snap-apps.txt"
FLATPAK_LIST="./flatpak-apps.txt"

echo "📦 Starting full application setup..."

# --------------------------------------------
# 1. APT INSTALL
# --------------------------------------------
if [[ -f "$APT_LIST" ]]; then
  echo "🚀 Installing APT apps..."
  sudo apt update && sudo apt upgrade -y
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    if dpkg -l | grep -qw "$pkg"; then
      echo "✅ $pkg is already installed (APT)"
    else
      echo "📥 Installing $pkg (APT)..."
      sudo apt install -y "$pkg"
    fi
  done < "$APT_LIST"
fi

# --------------------------------------------
# 2. SNAP INSTALL
# --------------------------------------------
if command -v snap &>/dev/null && [[ -f "$SNAP_LIST" ]]; then
  echo "🚀 Installing Snap apps..."
  while IFS= read -r snap_pkg; do
    [[ -z "$snap_pkg" || "$snap_pkg" =~ ^# ]] && continue
    if snap list | grep -qw "$snap_pkg"; then
      echo "✅ $snap_pkg is already installed (Snap)"
    else
      echo "📥 Installing $snap_pkg (Snap)..."
      sudo snap install "$snap_pkg"
    fi
  done < "$SNAP_LIST"
fi

# --------------------------------------------
# 3. FLATPAK INSTALL
# --------------------------------------------
if command -v flatpak &>/dev/null && [[ -f "$FLATPAK_LIST" ]]; then
  echo "🚀 Installing Flatpak apps..."
  # Ensure Flathub is added
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  while IFS= read -r fpkg; do
    [[ -z "$fpkg" || "$fpkg" =~ ^# ]] && continue
    if flatpak list | grep -qw "$(basename "$fpkg")"; then
      echo "✅ $fpkg is already installed (Flatpak)"
    else
      echo "📥 Installing $fpkg (Flatpak)..."
      flatpak install -y "$fpkg"
    fi
  done < "$FLATPAK_LIST"
fi

# --------------------------------------------
# 4. Custom .deb Packages
# --------------------------------------------
if [[ -d "$DEB_DIR" ]]; then
  echo "🚀 Installing local .deb packages..."
  for deb_file in "$DEB_DIR"/*.deb; do
    pkg_name=$(dpkg-deb -f "$deb_file" Package)
    if dpkg -l | grep -qw "$pkg_name"; then
      echo "✅ $pkg_name already installed (.deb)"
    else
      echo "📥 Installing $pkg_name from $deb_file"
      sudo dpkg -i "$deb_file" || sudo apt install -f -y
    fi
  done
fi

echo "✅ All done. Applications are installed."
```

---

## 📁 Folder & File Layout

```bash
install-apps.sh
apt-apps.txt
snap-apps.txt
flatpak-apps.txt
deb-packages/
  ├── teamviewer.deb
  ├── someapp.deb
```

---

## 📘 Example `apt-apps.txt`

```txt
# APT Apps
git
curl
zsh
vim
neofetch
```

## 📘 Example `snap-apps.txt`

```txt
# Snap Apps
code
postman
```

## 📘 Example `flatpak-apps.txt`

```txt
# Flatpak Apps
com.discordapp.Discord
com.visualstudio.code
org.gnome.Calculator
```

---

## 🚀 How to Use

```bash
chmod +x install-apps.sh
./install-apps.sh
```

---

Would you like me to:

* Add **unattended upgrades or reboots**?
* Convert this into a **portable setup script** for new machines (with dotfiles too)?
* Upload a GitHub-ready version?

Let me know and I’ll help you set it up even better.
 
