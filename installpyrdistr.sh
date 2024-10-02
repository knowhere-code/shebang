#!/bin/bash
# Скрипт для установки пакетов Пирамиды. Скрипт должен находиться в одной папке с пакетами.

# Проверка прав пользователя
if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  exit 1
fi

PYRAMID_DISTR=pyramid

PS3='Select index distribution: '

select opt in "Pyramid" "Pyrnet"
do
  case $opt in
      "Pyramid") break ;;
      "Pyrnet") PYRAMID_DISTR=pyrnet; break ;;
      *) echo "Command line arguments are incorrect!"; exit 1 ;;
  esac
done     

# Проверка наличия пакетов и лицензионных ключей в текущей директории
if ! ls ./$PYRAMID_DISTR-* &> /dev/null; then
  echo "$0 must be running in folder with distribution!"
  exit 1
fi

if ! ls ./p20.* &> /dev/null; then
  echo "Licension keys not found!"
  exit 1
fi

# Проверка наличия установленных служб Пирамиды
if ls /etc/systemd/system/Pyramid* &> /dev/null; then
  echo "Pyramid services are already installed! Try running the update script."
  systemctl status Pyramid* | cat
  exit 1
fi

# Определение пакетного менеджера
#PACKAGES_MANAGER=$(command -v yum &> /dev/null && echo "yum" || echo "apt")

PACKAGES_MANAGER="apt"
# Определение пакетного менеджера
if command -v yum &> /dev/null; then
  PACKAGES_MANAGER="yum"
elif command -v apt-get &> /dev/null; then #alt linux
  PACKAGES_MANAGER="apt-get"
fi 

# Массивы с именами пакетов и соответствующими шаблонами файлов
PACKAGES=(
  "$PYRAMID_DISTR-control"
  "$PYRAMID_DISTR-collector"
  "$PYRAMID_DISTR-user-web"
  "$PYRAMID_DISTR-client-web"
  "$PYRAMID_DISTR-integration"
  "$PYRAMID_DISTR-csproxy"
  "$PYRAMID_DISTR-usv"
  "$PYRAMID_DISTR-opc-server"
  "$PYRAMID_DISTR-opc-client"
  "$PYRAMID_DISTR-fias"
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

# Обновление/установка пакетов и настройка служб
for pkg in "${PACKAGES[@]}"; do
  echo "Trying to install $pkg"
  $PACKAGES_MANAGER install ./"$pkg"* -y

  case "$pkg" in
    "$PYRAMID_DISTR-control")
      echo "Copying and setting permissions for keys"
      cp -v ./p20.* /etc/$PYRAMID_DISTR-control/
      chmod -v a=rw /etc/$PYRAMID_DISTR-control/p20.*
      setfacl -m u:"$SUDO_USER":rwx /etc/$PYRAMID_DISTR-control/
      getfacl /etc/$PYRAMID_DISTR-control/
      ;;
    "$PYRAMID_DISTR-collector")
      echo "Adding user to dialout group"
      adduser "$SUDO_USER" dialout
      ;;
    "$PYRAMID_DISTR-usv")
      echo "Setting capabilities"
      setcap -v cap_sys_time+pie /bin/date
      setcap -v cap_sys_time,cap_dac_override+eip /sbin/hwclock
      ;;
  esac
done

# Установка и запуск служб
for srv in "${SERVICES_CAPTION[@]}"; do
  echo "Installing and starting $srv"
  $srv --install 2> /dev/null
  $srv --start 2> /dev/null
done

systemctl status Pyramid* | cat