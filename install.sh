#!/bin/bash
# ---------------------------
# VPNBarBuddy Install Script
# Version: v1.0 Secure Build
# Author: WilCF
# ---------------------------

function progress_bar() {
  echo -n "$1 "
  for i in {1..5}; do
    echo -n "▮"
    sleep 0.2
  done
  echo " Done!"
}

clear
echo "🌟 VPNBarBuddy Setup Starting..."
sleep 1

# --- Step 1: Dependency Check ---

echo ""
progress_bar "🔎 Checking for wg-quick (WireGuard tool)..."
if ! command -v wg-quick &> /dev/null; then
    echo "❌ Error: wg-quick not found. Install with: brew install wireguard-tools"
    exit 1
fi

progress_bar "🔎 Checking for osascript (for notifications)..."
if ! command -v osascript &> /dev/null; then
    echo "❌ Error: osascript missing. This should exist on macOS."
    exit 1
fi

# --- Step 2: Prepare folders ---

VPN_DIR="$HOME/vpnbarbuddy-scripts"
PLUGIN_DIR="$HOME/Library/Application Support/xbar/plugins"

echo ""
progress_bar "📁 Creating VPN scripts folder..."
mkdir -p "$VPN_DIR"

progress_bar "📁 Ensuring xbar plugin folder exists..."
mkdir -p "$PLUGIN_DIR"

# --- Step 3: Install scripts ---

progress_bar "🛠️ Writing VPN connection scripts..."

# vpnconnect.sh (with DNS leak detection!)
cat << EOF > "$VPN_DIR/vpnconnect.sh"
#!/bin/bash
# VPNBarBuddy Connect Script
# Connects and checks for DNS leaks

if [ -f /tmp/vpnconnected ]; then
  sudo wg-quick down \$(cat /tmp/vpnconnected)
  sudo networksetup -setdnsservers Wi-Fi empty
  rm -f /tmp/vpnconnected
fi

SERVER_NAME="\$1"
sudo wg-quick up "\$SERVER_NAME"
sudo networksetup -setdnsservers Wi-Fi 100.64.0.55 10.64.0.1

echo "\$SERVER_NAME" > /tmp/vpnconnected

sleep 2

DNS_SERVERS=\$(scutil --dns | grep 'nameserver' | awk '{print \$3}' | uniq)

DNS_OK="no"
for dns in \$DNS_SERVERS; do
  if [[ "\$dns" == "100.64.0.55" ]] || [[ "\$dns" == "10.64.0.1" ]]; then
    DNS_OK="yes"
  fi
done

if [[ "\$DNS_OK" == "yes" ]]; then
  osascript -e 'display notification "Connected to VPN: '"\$SERVER_NAME"'" with title "VPNBarBuddy" sound name "Submarine"'
else
  osascript -e 'display notification "Connected, but DNS Leak Detected!" with title "VPNBarBuddy" sound name "Glass"'
fi
EOF

# vpndisconnect.sh
cat << EOF > "$VPN_DIR/vpndisconnect.sh"
#!/bin/bash
# VPNBarBuddy Disconnect Script

if [ -f /tmp/vpnconnected ]; then
  sudo wg-quick down \$(cat /tmp/vpnconnected)
  sudo networksetup -setdnsservers Wi-Fi empty
  rm -f /tmp/vpnconnected
  osascript -e 'display notification "VPN Disconnected" with title "VPNBarBuddy" sound name "Frog"'
else
  osascript -e 'display notification "No VPN active to disconnect." with title "VPNBarBuddy"'
fi
EOF

chmod +x "$VPN_DIR/vpnconnect.sh" "$VPN_DIR/vpndisconnect.sh"

# --- Step 4: Create xbar plugin ---

progress_bar "🖼️ Creating xbar plugin..."

PLUGIN_PATH="$PLUGIN_DIR/vpnstatus.5s.sh"

cat << EOF > "$PLUGIN_PATH"
#!/bin/bash

WG_CONFIG_DIR="/etc/wireguard"
VPN_DIR="$HOME/vpnbarbuddy-scripts"

if [ -f /tmp/vpnconnected ]; then
  CURRENT_VPN=\$(cat /tmp/vpnconnected)
  echo "🟢 VPN: \$CURRENT_VPN | color=green"
else
  echo "🔴 No VPN | color=red"
fi

echo "---"

for config in \$WG_CONFIG_DIR/*.conf; do
  NAME=\$(basename "\$config" .conf)
  echo "Connect to \$NAME | bash=\$VPN_DIR/vpnconnect.sh param1=\$NAME terminal=false refresh=true"
done

echo "---"
echo "Disconnect VPN | bash=\$VPN_DIR/vpndisconnect.sh terminal=false refresh=true"
EOF

chmod +x "$PLUGIN_PATH"

# --- Step 5: Offer to install xbar ---

if [ ! -d "/Applications/xbar.app" ]; then
  echo ""
  read -p "❓ xbar not found. Would you like to download and install it now? (y/n): " INSTALL_XBAR
  INSTALL_XBAR=${INSTALL_XBAR:-y}

  if [ "\$INSTALL_XBAR" == "y" ]; then
    progress_bar "⬇️ Downloading and installing xbar..."
    curl -L -o ~/Downloads/xbar.zip https://github.com/matryer/xbar/releases/latest/download/xbar-darwin-x64.zip
    unzip ~/Downloads/xbar.zip -d ~/Downloads/xbar-temp
    mv ~/Downloads/xbar-temp/xbar.app /Applications/
    rm -rf ~/Downloads/xbar.zip ~/Downloads/xbar-temp
    echo "✅ xbar installed!"
  else
    echo "⚠️ Skipping xbar installation."
  fi
else
  echo "✅ xbar is already installed."
fi

# --- Step 6: Finish ---

echo ""
echo "🎉 VPNBarBuddy Setup Complete!"
echo "✅ VPN connect/disconnect scripts installed in: $VPN_DIR"
echo "✅ VPN status menu plugin installed in: $PLUGIN_DIR"
echo "✅ Auto DNS leak detection activated."
echo ""
echo "Enjoy secure VPN in your Mac menu bar! 🎛️"
