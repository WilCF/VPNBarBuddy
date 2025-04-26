# VPNBarBuddy: Your VPN Status and Connection Buddy for macOS

🎛️ **VPNBarBuddy** is a tiny, super-clean tool that:
- Lets you connect to any of your WireGuard VPN profiles right from the Mac menu bar
- Shows your VPN status live (🟢 Connected / 🔴 Not Connected)
- Pops macOS notifications when you connect or disconnect
- Prevents DNS leaks automatically

---

## ✨ Features

- **Multi-profile support**: Choose from all your WireGuard `.conf` files
- **No DNS leaks**: Forces secure DNS on VPN connect
- **Instant notifications**: macOS alerts for connection changes
- **Lightweight & private**: No tracking, no background apps
- **Fun Setup Experience**: Progress bars, clear instructions

---

## 📦 Install

Paste this into Terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/YOURUSERNAME/VPNBarBuddy/main/install.sh)

(Replace YOURUSERNAME with your GitHub username.)

    Follow the prompts.

    Open xbar and set plugin folder to ~/vpnbarbuddy-plugins (or wherever you chose).

🎯 Requirements

    macOS Catalina or newer

    WireGuard tools (brew install wireguard-tools)

    xbar (BitBar successor) (optional auto-install during setup)
