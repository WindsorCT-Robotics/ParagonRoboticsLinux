#!/usr/bin/env bash
set -euo pipefail

# 1. Map .NET 10 System-wide via systemd environment.d drop-ins.
# Fedora's dotnet SDK is installed under /usr/share/dotnet; this keeps it available
# to both desktop and terminal sessions.
mkdir -p /etc/environment.d
cat << 'EOF' > /etc/environment.d/60-dotnet.conf
DOTNET_ROOT=/usr/share/dotnet
PATH=$PATH:/usr/share/dotnet
EOF

# 2. Keep standard terminal fallback profile active for compatibility.
mkdir -p /etc/profile.d
cat << 'EOF' > /etc/profile.d/dotnet.sh
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT
EOF
