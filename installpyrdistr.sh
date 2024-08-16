#!/bin/bash
# Скрипт для установки пакетов Пирамиды. Скрипт должны лежать в одной папке с пакетами.

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  exit 1
fi

# Проверка наличия пакетов в текущей директории
if ! ls ./pyramid* &> /dev/null; then
  echo "$0 must be running in folder with distribution!"; echo ""
  exit 1
fi

# Проверка наличия лицензионных ключей
if ! ls ./p20.* &> /dev/null; then
  echo "Not found licension keys!"; echo ""
  exit 1
fi

# Проверка наличия установленных служб Пирамиды
if ls /etc/systemd/system/Pyramid* &> /dev/null; then
  echo "Pyramid services are already installed! Try run update script."; echo ""
  systemctl status Pyramid* | cat
  exit 1
fi

# Определение пакетного менеджера и команд
PACKET_MANAGER="apt"
if command -v yum &> /dev/null; then
  PACKET_MANAGER="yum"
fi 

# Массивы с именами пакетов и соответствующими шаблонами файлов
PACKAGES=(
  "pyramid-control"
  "pyramid-collector"
  "pyramid-user-web"
  "pyramid-client-web"
  "pyramid-integration"
  "pyramid-csproxy"
  "pyramid-usv"
  "pyramid-opc-server"
  "pyramid-opc-client"
)

SERVICES_CAPTION=(
  "ControlService"
  "CollectorService"
  "PyramidUserWeb"
  "PyramidClientWeb"
  "CSProxyService"
  "IntegrationService"
  "UsvTimeService"
  "OpcUaClientsService"
  "OpcUaServersService"
)

# Обновление/установка пакетов
for pkg in "${PACKAGES[@]}"; do

  echo "Try install $pkg"; echo ""
  $PACKET_MANAGER install ./"$pkg"*

  if [ "$pkg" = "pyramid-control" ]; then
    echo "Try copy and chmod keys"; echo ""
    cp -v ./p20.* /etc/pyramid-control/
    chmod -v a=rw /etc/pyramid-control/p20.*
    setfacl -m u:"$SUDO_USER":rwx /etc/pyramid-control/
    getfacl /etc/pyramid-control/
  fi

  if [ "$pkg" = "pyramid-collector" ]; then
    echo "Try add user into group dialout"; echo ""
    adduser "$SUDO_USER" dialout
  fi

  if [ "$pkg" = "pyramid-usv" ]; then
    echo "Try setcap"; echo ""
    setcap -v cap_sys_time+pie /bin/date
    setcap -v cap_sys_time,cap_dac_override+eip /sbin/hwclock
  fi
done

for srv in "${SERVICES_CAPTION[@]}"; do
    echo "Try install and run $srv"; echo ""
    $srv --install 2> /dev/null
    $srv --start 2> /dev/null
done

systemctl status Pyramid* | cat
