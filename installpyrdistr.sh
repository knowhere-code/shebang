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
  "PyramidUserWeb"
  "PyramidClientWeb"
  "CSProxyService"
  "IntegrationService"
  "OpcUaClientsService"
  "OpcUaServersService"
)

# Обновление пакетов
for pkg in "${PACKAGES[@]}"; do

  if [ "$pkg" = "pyramid-control" ]; then

    echo "Try install $pkg"; echo ""
    $PACKET_MANAGER install ./"$pkg"*

    echo "Try copy and chmod keys"; echo ""

    cp -v ./p20.* /etc/pyramid-control/
    chmod -v a=rw /etc/pyramid-control/p20.*
    sudo setfacl -m u:"$SUDO_USER":rwx /etc/pyramid-control/

    echo "Try install $pkg daemon"; echo ""
    ControlService --install
    ControlService --start
  fi

  if [ "$pkg" = "pyramid-collector" ]; then

    echo "Try install $pkg"; echo ""
    $PACKET_MANAGER install ./"$pkg"*

    echo "Try add user into group dialout"; echo ""
    adduser "$SUDO_USER" dialout

    echo "Try install and run $pkg daemon"; echo ""
    CollectorService --install
    CollectorService --start
  fi

  if [ "$pkg" = "pyramid-usv" ]; then
    echo "Try install $pkg"; echo ""
    $PACKET_MANAGER install ./"$pkg"*

    echo "Try setcap"; echo ""
    setcap cap_sys_time+pie /bin/date
    setcap cap_sys_time,cap_dac_override+eip /sbin/hwclock
    UsvTimeService --install
  fi
    echo "Try install $pkg"
    $PACKET_MANAGER install ./"$pkg"*
done

for srv in "${SERVICES_CAPTION[@]}"; do
    echo "Try install and run Pyramid services"; echo ""
    $srv --install
    $srv --start
done

systemctl status Pyramid* | cat
  exit 0