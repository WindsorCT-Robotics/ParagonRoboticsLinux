#!/usr/bin/env bash
set -euo pipefail

# 1. Map .NET 10 System-wide via systemd environment.d drop-ins
# This guarantees availability for both Wayland desktop actions and terminal prompts.
mkdir -p /etc/environment.d
cat << 'EOF' > /etc/environment.d/60-dotnet.conf
DOTNET_ROOT=/usr/lib64/dotnet
PATH=$PATH:/usr/lib64/dotnet
EOF

# 2. Keep standard terminal fallback profile active for compatibility
mkdir -p /etc/profile.d
cat << 'EOF' > /etc/profile.d/dotnet.sh
export DOTNET_ROOT=/usr/lib64/dotnet
export PATH=$PATH:$DOTNET_ROOT
EOF
