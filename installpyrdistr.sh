#!/bin/bash
# Скрипт для установки пакетов Пирамиды. Скрипт должен находиться в одной папке с пакетами.

# Проверка прав пользователя
if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  sudo "$0" "$@"
  exit
fi

# PYRAMID_DISTR=pyramid

# PS3='Select index distribution: '

# select opt in "Pyramid" "Pyrnet"
# do
#   case $opt in
#       "Pyramid") break ;;
#       "Pyrnet") PYRAMID_DISTR=pyrnet; break ;;
#       *) echo "Command line arguments are incorrect!"; exit 1 ;;
#   esac
# done  

RED_OS=false

if grep "RED OS" /etc/os-release &> /dev/null || grep "altlinux" /etc/os-release &> /dev/null; then
  RED_OS=true
fi
# Проверка наличия пакетов и лицензионных ключей в текущей директории
if ls ./pyrnet-* &> /dev/null; then
  PYRAMID_DISTR=pyrnet
elif ls ./pyramid-* &> /dev/null; then
  PYRAMID_DISTR=pyramid
else
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

# Определение пакетного менеджера
if command -v yum &> /dev/null; then
  PACKAGES_MANAGER="yum"
elif command -v dnf &> /dev/null; then
  PACKAGES_MANAGER="dnf"
elif command -v apt &> /dev/null; then
  PACKAGES_MANAGER="apt"
elif command -v apt-get &> /dev/null; then
  PACKAGES_MANAGER="apt-get"
else
  echo "No compatible package manager found (yum, apt-get, or apt)."
  exit 1
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
  if ! ls ./"$pkg"* &> /dev/null; then 
    echo "$pkg distr not found!"
    continue
  fi
  $PACKAGES_MANAGER install ./"$pkg"* -y
  case "$pkg" in
    "$PYRAMID_DISTR-control")
      echo "Copying and setting permissions for keys"
      if ! cp -v ./p20.* "/etc/$PYRAMID_DISTR-control/"; then
        exit 1
      fi
      chmod -v a=rw /etc/$PYRAMID_DISTR-control/p20.*
      setfacl -m u:"$SUDO_USER":rwx /etc/$PYRAMID_DISTR-control/
      getfacl /etc/$PYRAMID_DISTR-control/
      if $RED_OS; then
        CSConfigConsole
      fi
      ;;
    "$PYRAMID_DISTR-collector")
      echo "Adding user to dialout group"
      if ! adduser "$SUDO_USER" dialout &> /dev/null; then
        usermod -a -G dialout "$SUDO_USER" # for RedOS
      fi
      ;;

    "$PYRAMID_DISTR-user-web")
      if $RED_OS; then
        PyramidUserWebConfigConsole
      fi
    ;;

    "$PYRAMID_DISTR-client-web")
      if $RED_OS; then
        PyramidClientWebConfigConsole
      fi
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
  sleep 5
done

systemctl status Pyramid* | cat