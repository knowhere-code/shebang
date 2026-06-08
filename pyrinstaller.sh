#!/bin/bash
# author: Ametov S.I.
# Скрипт для установки пакетов Пирамиды. Скрипт должен находиться в одной папке с пакетами.

# Проверка прав пользователя
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

is_astra_ver_17(){
	if [ -f "/etc/astra_version" ] && grep "1.7" "/etc/astra_version" &> /dev/null; then
		echo "Обнаружена версия Astra 1.7.x"
    return 0
	else
		return 1
	fi
}

REPO_FILE="/etc/apt/sources.list.d/pyr_custom.list"

add_repo_apt(){
    local repo_line="deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free backports experimental"
    
    echo "Временное добавление репозитория: $repo_line"

    # Создание файла репозитория
    echo "$repo_line" | tee "$REPO_FILE" > /dev/null
    
    # Импорт GPG ключа (если нужен)
    # wget -qO - https://example.com/key.gpg | apt-key add -
    
    # Обновление списка пакетов
    echo "Выполнение apt update..."
    apt update
    
    echo "Готово!"
}

del_repo_apt(){
	[ -f "$REPO_FILE" ] && rm -v $REPO_FILE && apt update
}


RED_OS=false

if [ -e /etc/redos-release ] || grep "RED OS" /etc/os-release &> /dev/null || grep "altlinux" /etc/os-release &> /dev/null; then
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

check_installed_pyr(){
  # Проверка наличия установленных служб Пирамиды
  if ls /etc/systemd/system/Pyramid* &> /dev/null; then
    echo "Pyramid services are already installed! Try running the update script."
    systemctl status Pyramid* | cat
    exit 1
  fi
}
#check_installed_pyr

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

# Словарь с именами пакетов и соответствующими шаблонами файлов

declare -A PACKAGES_DIC=(
    [ControlService]="$PYRAMID_DISTR-control"
    [CollectorService]="$PYRAMID_DISTR-collector"
    [PyramidUserWeb]="$PYRAMID_DISTR-user-web"
    [PyramidClientWeb]="$PYRAMID_DISTR-client-web"
    [IntegrationService]="$PYRAMID_DISTR-integration"
    [CSProxyService]="$PYRAMID_DISTR-csproxy"
    [UsvTimeService]="$PYRAMID_DISTR-usv"
    [OpcUaServersService]="$PYRAMID_DISTR-opc-server"
    [OpcUaClientsService]="$PYRAMID_DISTR-opc-client"
)

if [ $# -eq 0 ]; then
    # Получить все значения
    values=("${PACKAGES_DIC[@]}")
else
    # Получить значения по ключам
    values=()
    for key in "$@"; do
        values+=("${PACKAGES_DIC[$key]}")
    done
fi

echo "${values[@]}"

is_astra_ver_17 && add_repo_apt

# Обновление/установка пакетов и настройка служб
for pkg in "${values[@]}"; do
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

is_astra_ver_17 && del_repo_apt

# Установка и запуск служб
for srv in "${!PACKAGES_DIC[@]}"; do
  echo "Installing and starting demon $srv"
  $srv --install 2> /dev/null
  $srv --start 2> /dev/null
  sleep 3
done

systemctl status Pyramid* --no-pager