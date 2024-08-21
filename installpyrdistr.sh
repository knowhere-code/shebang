#!/bin/bash
# Скрипт для установки пакетов Пирамиды. Скрипт должен находиться в одной папке с пакетами.

# Проверка прав пользователя
if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  exit 1
fi

# Проверка наличия пакетов и лицензионных ключей в текущей директории
if ! ls ./pyramid* &> /dev/null; then
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
PACKAGES_MANAGER=$(command -v yum &> /dev/null && echo "yum" || echo "apt")

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
  "pyramid-fias"
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
    "pyramid-control")
      echo "Copying and setting permissions for keys"
      cp -v ./p20.* /etc/pyramid-control/
      chmod -v a=rw /etc/pyramid-control/p20.*
      setfacl -m u:"$SUDO_USER":rwx /etc/pyramid-control/
      getfacl /etc/pyramid-control/
      ;;
    "pyramid-collector")
      echo "Adding user to dialout group"
      adduser "$SUDO_USER" dialout
      ;;
    "pyramid-usv")
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