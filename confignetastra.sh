#!/bin/bash

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  exit 1
fi

DNS=192.168.10.8

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

echo "Select network interface:"
select opt in $(ls /sys/class/net)
do
  echo "You have chosen $opt"
  ETH=$opt
  break
done

 if [ -z "$ETH" ];
 then
    echo "Network interface incorrect"
    exit 1
 fi

read -rp "Enter ip adress (169.254.x.x) local host: " IP

if ! echo "${IP}" | grep -q -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\$" &> /dev/null; then
  echo "Invalid IP"; exit 1
fi

echo "Masking NetworkManager..."
systemctl stop NetworkManager
systemctl --now mask NetworkManager

echo "Create config /etc/network/interfaces"

cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback
auto $ETH
iface $ETH inet static
address $IP
netmask 255.255.0.0
gateway 169.254.1.254
EOF

if ifquery "$ETH" &> /dev/null; then
    echo "Check net config - Ok"
else
    echo "Check net config - Error"
    ifquery "$ETH"
    exit 1
fi

echo "DNS config..."
echo "nameserver $DNS" > /etc/resolv.conf

echo "You must restart OS. Please enter 'y' or 'n'"
if input_yes_no ; then
    reboot -f
fi

# echo "Try UP network interface $ETH"
# systemctl restart ifupdown-pre.service && systemctl restart networking.service
# ifdown "$ETH" && ifup "$ETH"
# echo "Done"