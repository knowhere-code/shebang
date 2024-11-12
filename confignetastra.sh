#!/bin/bash

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  sudo "$0" "$@"
  exit
fi

DNS=192.168.10.8
GATEWAY=169.254.1.254

function input_yes_no() {
    while read -r answer; do
        case "${answer}" in
        "Yes" | "y" | "yes")
            return 0
            ;;
        "No" | "n" | "no" | "")
            echo "No"; return 1
            ;;
        *)
            echo "Please enter 'y' or 'n': "
            ;;
        esac
    done
}

#ETH=$(ip -br link show | awk '{print $1}' | tail -1)
# IFS=$'\n'
# ETH_LIST=($(ls /sys/class/net))

PS3="Select network interface: "
select opt in $(ls /sys/class/net); do
  if [ -n "$opt" ] && [ "$opt" != "lo" ]; then
    echo "You have chosen $opt"
    ETH=$opt
    break
  else
    echo "Invalid choice. Please select a valid network interface."
  fi
done

read -rp "Enter IP address (169.254.x.x) for local host: " IP

# Improved IP address validation
if ! [[ $IP =~ ^169\.254\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  echo "Invalid IP address format. Please provide a valid IP (e.g., 169.254.x.x)."
  exit 1
fi

echo "Masking NetworkManager..."
systemctl stop NetworkManager
systemctl --now mask NetworkManager

echo "Creating config /etc/network/interfaces"

cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto $ETH
iface $ETH inet static
address $IP
netmask 255.255.0.0
gateway $GATEWAY
EOF

if ifquery "$ETH" &> /dev/null; then
    echo "Network configuration for $ETH is valid."
else
    echo "Error in network configuration for $ETH."
    ifquery "$ETH"
    exit 1
fi

echo "Configuring DNS..."
echo "nameserver $DNS" > /etc/resolv.conf

echo "You must restart the OS for changes to take effect. Would you like to restart now? (y/n)"
if input_yes_no ; then
    reboot -f
else
    echo "Please reboot manually to apply changes."
fi

# Optionally: Uncomment these lines if you want to restart network interface instead of rebooting
# echo "Trying to bring up network interface $ETH"
# systemctl restart ifupdown-pre.service && systemctl restart networking.service
# ifdown "$ETH" && ifup "$ETH"
# echo "Network interface $ETH is up and running."