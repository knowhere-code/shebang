#!/bin/bash
# Скрипт для массового обновления пакетов Пирамиды. Должен лежать в одной папке с пакетами.

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  exit 1
fi

# Проверка наличия пакетов в текущей директории
if ! ls ./pyramid* &> /dev/null; then
  echo "$0 must be running in folder with distribution!"
  exit 1
fi

# Определение пакетного менеджера и команд
if command -v apt &> /dev/null; then
  PACKAGES_MANAGER_COMMAND="apt install -y"
  PACKAGES_MANAGER_CHECK_CMD="dpkg-query -l"
  APT_OPT="grep ii"
elif command -v yum &> /dev/null; then
  PACKAGES_MANAGER_COMMAND="yum install -y"
  PACKAGES_MANAGER_CHECK_CMD="rpm -qa --last"
  APT_OPT="cat"
else
  echo "No suitable package manager found. Exiting."
  exit 1
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
  "pyramid-fias"
)

# Обновление пакетов
for pkg in "${PACKAGES[@]}"; do
  if $PACKAGES_MANAGER_CHECK_CMD "$pkg*" | $APT_OPT &> /dev/null; then
    $PACKAGES_MANAGER_COMMAND ./"$pkg"*
  fi
done

$PACKAGES_MANAGER_CHECK_CMD "pyramid-*" | $APT_OPT