#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# Enable GPU acceleration for Vivaldi flatpak
echo "Configuring GPU acceleration overrides for Vivaldi..."
flatpak override --system --device=dri com.vivaldi.Vivaldi

# Provision OnShape PWA
mkdir -p /usr/share/applications
cat << 'EOF' > /usr/share/applications/onshape.desktop
[Desktop Entry]
Version=1.0
Name=Onshape CAD
Comment=Privacy-focused 3D CAD interface for FRC team
Exec=flatpak run com.vivaldi.Vivaldi --app=https://onshape.com
Icon=com.onshape.app
Terminal=false
Type=Application
Categories=Network;WebBrowser;Development;
EOF