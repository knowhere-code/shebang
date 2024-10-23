#!/bin/bash
# Скрипт создания службы виртуальных портов socat под UsvTimeService
# IP адрес определяется переменной IP, порт - PORT, виртуальный COM порт - TTYS

TTYS=/dev/ttyS0
IP=192.168.10.118
PORT=50005

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  sudo "$0" "$@"
  exit
fi

if ! which socat &> /dev/null
then
    echo "Socat is not installed. Try install socat..."
    if command -v apt &>/dev/null; then
        apt install socat -y
    else
        yum install socat -y
    fi
fi

if ! which socat &> /dev/null; then
  echo "Socat is not installed."
  exit 1
fi

SOCKET=$IP:$PORT
SOCAT_EXEC=$(which socat)
SERVICE_CAPTION=usv-socat.service

if [ -f /etc/systemd/system/$SERVICE_CAPTION ] 
then
    echo "$SERVICE_CAPTION is already installed!"
    systemctl status $SERVICE_CAPTION | cat
    exit 1
fi

cat << EOF > /etc/systemd/system/$SERVICE_CAPTION
[Unit]
Description=Socat virtual COM (ttys) port for UsvTimeService
After=network.target

[Service]
ExecStart=$SOCAT_EXEC -d -d pty,link=$TTYS,raw,mode=777 tcp:$SOCKET
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl enable $SERVICE_CAPTION
systemctl start $SERVICE_CAPTION
systemctl status $SERVICE_CAPTION | cat