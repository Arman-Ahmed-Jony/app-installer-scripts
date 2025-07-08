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
    snap_name=$(echo "$snap_pkg" | awk '{print $1}')
    snap_opts=$(echo "$snap_pkg" | cut -d' ' -f2-)
    if snap list | grep -qw "$snap_name"; then
      echo "✅ $snap_name is already installed (Snap)"
    else
      echo "📥 Installing $snap_name (Snap)..."
      sudo snap install $snap_name $snap_opts
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

# ---- Install NVM (Node Version Manager) ----
if [[ ! -d "$HOME/.nvm" ]]; then
  echo "⬢ Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
else
  echo "✅ NVM already installed."
fi

echo "✅ All done. Applications are installed."

# -----------------------------
# 5. SUMMARY OF INSTALLED APPS
# -----------------------------
echo -e "\n==============================="
echo "INSTALLATION SUMMARY"
echo "==============================="

# Function to get APT package version
get_apt_version() {
  dpkg -s "$1" 2>/dev/null | awk -F': ' '/^Version/ {print $2}'
}

# Function to get Snap package version
get_snap_version() {
  snap info "$1" 2>/dev/null | awk -F': ' '/^installed:/ {print $2}' | awk '{print $1}'
}

# Function to print summary table
echo "\nAPT Packages:"
printf "%-25s %-15s %-20s\n" "Package" "Status" "Version"
printf "%-25s %-15s %-20s\n" "-------" "------" "-------"
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  if dpkg -l | grep -qw "$pkg"; then
    status="Already present"
    version=$(get_apt_version "$pkg")
  else
    status="Not installed"
    version="-"
  fi
  printf "%-25s %-15s %-20s\n" "$pkg" "$status" "$version"
done < "$APT_LIST"

echo "\nSnap Packages:"
printf "%-25s %-15s %-20s\n" "Package" "Status" "Version"
printf "%-25s %-15s %-20s\n" "-------" "------" "-------"
while IFS= read -r snap_pkg; do
  [[ -z "$snap_pkg" || "$snap_pkg" =~ ^# ]] && continue
  if snap list | grep -qw "$snap_pkg"; then
    status="Already present"
    version=$(get_snap_version "$snap_pkg")
  else
    status="Not installed"
    version="-"
  fi
  printf "%-25s %-15s %-20s\n" "$snap_pkg" "$status" "$version"
done < "$SNAP_LIST"

echo "\nUncategorized Packages (version may not be available):"
printf "%-25s %-15s %-20s\n" "Package" "Status" "Version"
printf "%-25s %-15s %-20s\n" "-------" "------" "-------"
while IFS= read -r upkg; do
  [[ -z "$upkg" || "$upkg" =~ ^# ]] && continue
  # Try APT first
  if dpkg -l | grep -qw "$upkg"; then
    status="Already present (APT)"
    version=$(get_apt_version "$upkg")
  # Try Snap
  elif snap list | grep -qw "$upkg"; then
    status="Already present (Snap)"
    version=$(get_snap_version "$upkg")
  else
    status="Not installed"
    version="-"
  fi
  printf "%-25s %-15s %-20s\n" "$upkg" "$status" "$version"
done < "./uncategorized-apps.txt"

echo -e "\n==============================="
echo "End of summary."
echo "==============================="

