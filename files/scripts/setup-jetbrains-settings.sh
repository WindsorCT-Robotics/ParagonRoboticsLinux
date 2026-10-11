#!/bin/bash
# Seeds JetBrains Toolbox settings with auto-update disabled.
# Usage: ./setup-jetbrains-settings.sh <toolbox_dir>
set -euo pipefail

TOOLBOX_DIR="${1:?usage: setup-jetbrains-settings.sh <toolbox_dir>}"
cat > "${TOOLBOX_DIR}/.settings.json" << 'SETTINGS'
{
    "advanced": {
        "build_for_installed": true
    },
    "install_location": "/usr/share/JetBrains/apps",
    "shell_scripts": {
        "location": "/usr/share/JetBrains/Toolbox/scripts"
    },
    "statistics": {
        "allow": true
    },
    "ui": {
        "theme": "dark"
    },
    "tools": {
        "update_all_automatically": false
    },
    "plugins": {
        "plugins_auto_updater": false
    },
    "jetbrains_account": {
        "active": ""
    },
    "disk_usage": {
        "notification_threshold_bytes": 10737418240
    }
}
SETTINGS

echo "Seeded JetBrains settings at ${TOOLBOX_DIR}/.settings.json"
