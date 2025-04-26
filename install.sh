#!/bin/bash
# ---------------------------
# VPNBarBuddy - Your macOS Menu Bar VPN Companion
# Author: (YourNameHere)
# Description:
#   - Supports multiple WireGuard profiles
#   - Auto-detects tools
#   - Pops macOS notifications
#   - Shows connection status in menu bar
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

# --- Step 1: Auto-Detect Dependencies ---
echo ""
progress_bar "🔎 Checking for wg-quick (WireGuard tool)..."
if ! command -v wg-quick &> /dev/null; then
    echo "❌ Error: wg-quick could not be found."
    echo "➡️  Please install WireGuard tools first (brew install wireguard-tools)."
    exit 1
fi

progress_bar "🔎 Checking for osascript (notifications)..."
if ! command -v osascript &> /dev/null; then
    echo "❌ Error: osascript not found. Notifications won't work."
    exit 1
fi

# --- Step 2: Prompt for Configuration ---

echo ""
echo "📍 Setup Configuration:"
read -p "Enter the folder for your VPN scripts (default: ~/vpnbarbuddy-scripts): " VPN_DIR
VPN_DIR=${VPN_DIR:-~/vpnbarbuddy-scripts}

read -p "Enter the folder for xbar plugins (default: ~/vpnbarbuddy-plugins): " PLUGIN_DIR
PLUGIN_DIR=${PLUGIN_DIR:-~/vpnbarbuddy-plugins}

read -p "Enter the folder where your WireGuard configs live (default: /etc/wireguard): " WG_CONFIG_DIR
WG_CONFIG_DIR=${WG_CONFIG_DIR:-/etc/wireguard}

progress_bar "📁 Creating folders..."
mkdir -p "$VPN_DIR"
mkdir -p "$PLUGIN_DIR"

# --- Step 3: Create VPN Scripts ---

progress_bar "🛠️ Creating VPN connection scripts..."

cat << EOF > "$VPN_DIR/vpnconnect.sh"
#!/bin/bash
# Disconnect existing VPN if any
if [ -f /tmp/vpnconnected ]; then
  sudo wg-quick down \$(cat /tmp/vpnconnected)
  sudo networksetup -setdnsservers Wi-Fi empty
  rm -f /tmp/vpnconnected
fi

# Connect to new VPN
SERVER_NAME="\$1"
sudo wg-quick up "\$SERVER_NAME"
sudo networksetup -setdnsservers Wi-Fi 100.64.0.55 10.64.0.1
echo "\$SERVER_NAME" > /tmp/vpnconnected

# Send macOS notification
osascript -e 'display notification "Connected to VPN: '"\$SERVER_NAME"'" with title "VPNBarBuddy" sound name "Submarine"'
EOF

cat << EOF > "$VPN_DIR/vpndisconnect.sh"
#!/bin/bash
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

# --- Step 4: Create xbar Plugin ---

progress_bar "🖼️ Creating xbar menu plugin..."

PLUGIN_PATH="$PLUGIN_DIR/vpnstatus.5s.sh"

cat << EOF > "$PLUGIN_PATH"
#!/bin/bash

WG_CONFIG_DIR="$WG_CONFIG_DIR"
VPN_DIR="$VPN_DIR"

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

# --- Step 5: Offer xbar Installation ---

if [ ! -d "/Applications/xbar.app" ]; then
  echo ""
  read -p "xbar not found. Would you like to download and install xbar now? (y/n): " INSTALL_XBAR
  INSTALL_XBAR=${INSTALL_XBAR:-y}

  if [ "$INSTALL_XBAR" == "y" ]; then
    progress_bar "⬇️ Downloading and installing xbar..."
    curl -L -o ~/Downloads/xbar.zip https://github.com/matryer/xbar/releases/latest/download/xbar-darwin-x64.zip
    unzip ~/Downloads/xbar.zip -d ~/Downloads/xbar-temp
    mv ~/Downloads/xbar-temp/xbar.app /Applications/
    rm -rf ~/Downloads/xbar.zip ~/Downloads/xbar-temp
    echo "✅ xbar installed to /Applications."
    echo "⚡ Please open xbar manually and set the plugin folder to: $PLUGIN_DIR"
  else
    echo "⚠️ Skipping xbar installation. You can install it later from https://xbarapp.com/"
  fi
else
  echo "✅ xbar is already installed."
fi

# --- Step 6: Final Message ---

echo ""
echo "🎉 VPNBarBuddy Setup Complete!"
echo "🛡️  Use your Mac menu bar to connect/disconnect Mullvad VPN servers."
echo "🟢 Green = Connected  |  🔴 Red = Disconnected"
echo "🔔 macOS Notifications enabled for connection status."
echo ""
echo "REMINDER: Set xbar plugin folder to $PLUGIN_DIR inside xbar settings."
