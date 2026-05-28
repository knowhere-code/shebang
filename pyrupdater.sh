#!/bin/bash
# author: Ametov S.I.
# Скрипт для массового обновления пакетов Пирамиды. Должен лежать в одной папке с пакетами.

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  sudo "$0" "$@"
  exit
fi
echo "Start $0"
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

# Проверка наличия пакетов в текущей директории
if ls ./pyrnet-* &> /dev/null; then
  PYRAMID_DISTR=pyrnet
elif ls ./pyramid-* &> /dev/null; then
  PYRAMID_DISTR=pyramid
else
  echo "$0 must be running in folder with distribution!"
  exit 1
fi

YES_COMMAND=()

if [ -n "$1" ] && [ "$1" = "-y" ]; then
  if command -v yes &> /dev/null; then
    YES_COMMAND=(yes "")
  fi
fi

# Определение пакетного менеджера и команд
if command -v apt &> /dev/null; then
  PACKAGES_MANAGER_COMMAND="apt install -y"
  PACKAGES_MANAGER_CHECK_CMD="dpkg-query -l"
  APT_OPT="grep ii"
elif command -v yum &> /dev/null; then
  PACKAGES_MANAGER_COMMAND="yum install -y"
  PACKAGES_MANAGER_CHECK_CMD="rpm -qa --last"
  APT_OPT="grep x86"
 elif command -v dnf &> /dev/null; then
  PACKAGES_MANAGER_COMMAND="dnf install -y"
  PACKAGES_MANAGER_CHECK_CMD="rpm -qa --last"
  APT_OPT="grep x86" 
elif command -v apt-get &> /dev/null; then #alt linux
  PACKAGES_MANAGER_COMMAND="apt-get install -y"
  PACKAGES_MANAGER_CHECK_CMD="rpm -qa --last"
  APT_OPT="grep x86"
else
  echo "No suitable package manager found. Exiting."
  exit 1
fi 


# Список сервисов для проверки и обнговления
declare -A SERVICES=(
    ["$PYRAMID_DISTR-control"]="PyramidControl.service"
    ["$PYRAMID_DISTR-collector"]="PyramidCollector.service"
    ["$PYRAMID_DISTR-user-web"]="PyramidUserWeb.service"
    ["$PYRAMID_DISTR-client-web"]="PyramidClientWeb.service"
    ["$PYRAMID_DISTR-integration"]="PyramidIntegrationService.service"
    ["$PYRAMID_DISTR-csproxy"]="PyramidProxyControl.service"
    ["$PYRAMID_DISTR-usv"]="PyramidUsvTime.service"
    ["$PYRAMID_DISTR-opc-server"]="PyramidOpcUaServersService.service"
    ["$PYRAMID_DISTR-opc-client"]="PyramidOpcUaClientsService.service"
)

# Функция проверки, установлен ли сервис
is_service_installed() {
    local service_name="$1"
    local service_file="/etc/systemd/system/${service_name}"
    
    if [ -f "$service_file" ]; then
        return 0  # Установлен
    else
        return 1  # Не установлен
    fi
}

# Обновление пакетов
for pkg in "${!SERVICES[@]}"; do
  if ! is_service_installed "${SERVICES[$pkg]}"; then 
    echo "${pkg} сервис не найден, обновление пропущено."
    continue
  fi
  if $PACKAGES_MANAGER_CHECK_CMD "$pkg*" | $APT_OPT &> /dev/null; then
    if [ ${#YES_COMMAND[@]} -gt 0 ]; then
      "${YES_COMMAND[@]}" | $PACKAGES_MANAGER_COMMAND ./"$pkg"*
    else
      $PACKAGES_MANAGER_COMMAND ./"$pkg"* # Без pipe!
    fi
  fi
done

$PACKAGES_MANAGER_CHECK_CMD "$PYRAMID_DISTR-*" | $APT_OPT