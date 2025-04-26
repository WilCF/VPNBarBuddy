#!/bin/bash
# ---------------------------
# VPNBarBuddy - The One-Click VPN Status Tool for macOS
# Author: WilCF
# Description:
#   - Supports multiple WireGuard profiles
#   - Auto-detects tools
#   - Pops macOS notifications
#   - Shows connection status in Mac menu bar
#   - No manual setup needed for plugin folder
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
    echo "➡️  Please install WireGuard tools first: brew install wireguard-tools"
    exit 1
fi

progress_bar "🔎 Checking for osascript (notifications)..."
if ! command -v osascript &> /dev/null; then
    echo "❌ Error: osascript not found. Notifications won't work."
    exit 1
fi

# --- Step 2: Setup Script and Plugin Folders ---

VPN_DIR="$HOME/vpnbarbuddy-scripts"
PLUGIN_DIR="$HOME/Library/Application Support/xbar/plugins"

echo ""
progress_bar "📁 Creating VPN script folder..."
mkdir -p "$VPN_DIR"

progress_bar "📁 Ensuring xbar plugin folder exists..."
mkdir -p "$PLUGIN_DIR"

# --- Step 3: Create VPN Scripts ---

progress_bar "🛠️ Creating VPN connect and disconnect scripts..."

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

progress_bar "🖼️ Creating VPNBarBuddy xbar plugin..."

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

# --- Step 5: Offer to Install xbar if Needed ---

if [ ! -d "/Applications/xbar.app" ]; then
  echo ""
  read -p "❓ xbar not found. Would you like to download and install xbar now? (y/n): " INSTALL_XBAR
  INSTALL_XBAR=${INSTALL_XBAR:-y}

  if [ "$INSTALL_XBAR" == "y" ]; then
    progress_bar "⬇️ Downloading and installing xbar..."
    curl -L -o ~/Downloads/xbar.zip https://github.com/matryer/xbar/releases/latest/download/xbar-darwin-x64.zip
    unzip ~/Downloads/xbar.zip -d ~/Downloads/xbar-temp
    mv ~/Downloads/xbar-temp/xbar.app /Applications/
    rm -rf ~/Downloads/xbar.zip ~/Downloads/xbar-temp
    echo "✅ xbar installed to /Applications."
  else
    echo "⚠️ Skipping xbar installation. You can install it later from https://xbarapp.com/"
  fi
else
  echo "✅ xbar is already installed."
fi

# --- Step 6: Final Message ---

echo ""
echo "🎉 VPNBarBuddy Setup Complete!"
echo "🛡️  VPN connect/disconnect scripts installed in: $VPN_DIR"
echo "🖼️  xbar plugin installed in: $PLUGIN_DIR"
echo ""
echo "✅ If xbar was already running, your VPNBarBuddy menu should now appear automatically."
echo "🔔 You'll get macOS notifications when you connect/disconnect."
echo ""
echo "No manual folder picking needed. Enjoy! 🎉"
