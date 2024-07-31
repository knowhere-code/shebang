#!/bin/bash
# Выдать скрипту права sudo chmod +x getpyrinfo.sh
# Запускать командой sudo ./getpyrinfo.sh &> getpyrinfo.log
# На выходе архив с конфигурацией pyrconfig.tar.gz и лог getpyrinfo.log

declare -A PATHS=(
    [CS]=/usr/lib/pyramid-control
    [UWEB]=/usr/lib/pyramid-user-web
    [CWEB]=/usr/lib/pyramid-client-web
    [COL]=/usr/lib/pyramid-collector
    [FIAS]=/usr/lib/pyramid-fias
    [INTER]=/usr/lib/pyramid-integration
    [USV]=/usr/lib/pyramid-usv
    [COPC]=/usr/lib/pyramid-opc-client
    [SOPC]=/usr/lib/pyramid-opc-server
    [CSPROX]=/usr/lib/pyramid-csproxy
    [CS_NET]=/usr/lib/pyrnet-control
    [UWEB_NET]=/usr/lib/pyrnet-user-web
    [CWEB_NET]=/usr/lib/pyrnet-client-web
    [COL_NET]=/usr/lib/pyrnet-collector
    [FIAS_NET]=/usr/lib/pyrnet-fias
    [INTER_NET]=/usr/lib/pyrnet-integration
    [USV_NET]=/usr/lib/pyrnet-usv
    [COPC_NET]=/usr/lib/pyrnet-opc-client
    [SOPC_NET]=/usr/lib/pyrnet-opc-server
    [CSPROX_NET]=/usr/lib/pyrnet-csproxy
)

PYRAMID_DISTR=pyramid
CS_STATUS=0

echo "***********************************************************************"
echo " Quick get Pyramid 2.0 information script start..."
echo "***********************************************************************"

for key in CS COL UWEB; do
    if [ -d "${PATHS[${key}_NET]}" ]; then
        PYRAMID_DISTR=pyrnet
        break
    fi
done

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0 &> getpyrinfo.log'"
  exit 1
fi

echo ""
echo "***********************************************************************"
echo " System information"
echo "***********************************************************************"

echo "Kernel $(uname -r); Machine $(uname -m)"
cat /etc/*release*
echo ""

[ -e "/etc/astra_version" ] && echo "AstraLinux version: $(cat /etc/astra_version)" && echo ""

df -h
echo ""

free -h
echo ""

lscpu
echo ""
echo "Virtual machine: $(systemd-detect-virt)"

echo ""
echo "***********************************************************************"
echo " SElinux info"
echo "***********************************************************************"

command -v sestatus &>/dev/null && sestatus

echo ""
echo "***********************************************************************"
echo " Firewall info"
echo "***********************************************************************"

command -v firewall-cmd &>/dev/null && firewall-cmd --state
command -v ufw &>/dev/null && ufw status

echo ""
echo "***********************************************************************"
echo " Pyramid installed packages"
echo "***********************************************************************"

for key in CS UWEB CWEB COL FIAS INTER USV CSPROX COPC SOPC; do
    if [ -d "${PATHS[$key]}" ] || [ -d "${PATHS[${key}_NET]}" ]; then
        echo "Installed ${PYRAMID_DISTR}-$(echo $key | tr '[:upper:]' '[:lower:]')"
        [ "$key" = "CS" ] && CS_STATUS=1
    fi
done

echo ""

if command -v rpm &>/dev/null; then
    rpm -qa --last "${PYRAMID_DISTR}*"
fi

if command -v dpkg-query &>/dev/null; then
    dpkg-query -l "${PYRAMID_DISTR}*" | grep ii | awk '{print $1, $2, $3}'
fi

echo ""
echo "***********************************************************************"
echo " Kaspersky"
echo "***********************************************************************"

[ -d /opt/kaspersky ] && echo "Installed Kaspersky!"

echo ""
echo "***********************************************************************"
echo " Pyramid services running"
echo "***********************************************************************"

systemctl --type=service --state=running | grep Pyramid

echo ""
echo "***********************************************************************"
echo " ControlService run by user info"
echo "***********************************************************************"

TEMPLATE_CS="ControlService"
PID=$(pgrep -i "${TEMPLATE_CS}*")
if [ -n "$PID" ]; then
    USER_CS=$(ps -o user= -p "$PID")
    USER_GR=$(groups "$USER_CS")
    echo "ControlService (pid=$PID) run by $USER_GR"
else
    echo "ControlService is not running or installed!"
fi

echo ""
echo "***********************************************************************"
echo " CollectorService run by user info"
echo "***********************************************************************"

TEMPLATE_COL="CollectorService"
PID=$(pgrep -i "${TEMPLATE_COL}*")
if [ -n "$PID" ]; then
    USER_COL=$(ps -o user= -p "$PID")
    USER_GR_COL=$(groups "$USER_COL")
    echo "$TEMPLATE_COL (pid=$PID) run by $USER_GR_COL"
else
    echo "CollectorService is not running or installed!"
fi

echo ""
echo "***********************************************************************"
echo " Astra Linux permissions"
echo "***********************************************************************"

if [ -n "$USER_CS" ] && command -v pdpl-user &>/dev/null; then
    ASTRA_USER_PERM=$(pdpl-user "$USER_CS")
    if [ -n "$ASTRA_USER_PERM" ]; then
        echo "ASTRA USER ($USER_CS) MAX PERMISSION (MUST BE 0:63:0x0:0x0):"
        echo "$ASTRA_USER_PERM"
        echo ""
        echo "\"Command to set max permissions: sudo pdpl-user -i 63 $USER_CS\""
    fi
fi
echo ""

if command -v astra-modeswitch &>/dev/null; then
    echo "astra-modeswitch: $(astra-modeswitch getname)"
    echo "astra-mac-control status: $(astra-mac-control status)"
    echo "astra-mic-control status: $(astra-mic-control status)"
fi

echo ""
echo "***********************************************************************"
echo " Pyramid dir etc ControlService info"
echo "***********************************************************************"

ls -ld /etc/${PYRAMID_DISTR}-control/
echo ""
getfacl /etc/${PYRAMID_DISTR}-control/

echo ""
echo "***********************************************************************"
echo " Cap for UsvTimeService"
echo "***********************************************************************"

getcap /bin/date
getcap /sbin/hwclock

echo "Must be:
    /bin/date = cap_sys_time+pie 
    /sbin/hwclock = cap_dac_override,cap_sys_time+eip"

echo ""
echo "***********************************************************************"
echo " Pyramid dirs cache info"
echo "***********************************************************************"

ls -ld /var/cache/pyramid/*/

echo ""
echo "***********************************************************************"
echo " Pyramid dirs and files RDContent info"
echo "***********************************************************************"

ls -ld /var/cache/pyramid/RDContent/
ls -l --group-directories-first /var/cache/pyramid/RDContent/

echo ""
echo "***********************************************************************"
echo " Pyramid dirs ReportHelpers and ImportSheets info"
echo "***********************************************************************"
# версии >= 10.9 каталог ReportHelpers теперь в БД
ls -ld /var/cache/pyramid/RDContent/ReportHelpers
ls -l /var/cache/pyramid/RDContent/ReportHelpers
echo ""
ls -ld /var/cache/pyramid/RDContent/ImportSheets
ls -l /var/cache/pyramid/RDContent/ImportSheets/Helpers*

echo ""
echo "***********************************************************************"
echo " Pyramid dirs share"
echo "***********************************************************************"

ls -ld /usr/share/pyramid
ls -l --group-directories-first /usr/share/pyramid

echo ""
echo "***********************************************************************"
echo " Pyramid dir logs info"
echo "***********************************************************************"

ls -ld /var/log/pyramid/; ls -ld /var/log/pyramid/*/

echo ""
echo "***********************************************************************"
echo " Maybe not correct permission for pyramid dirs"
echo "***********************************************************************"

if [ -n "$USER_CS" ] && [ $CS_STATUS -eq 1 ]; then
    find /var/cache/pyramid -type d \( -not -perm 777 -and -not -user "$USER_CS" \) -ls
    find /var/log/pyramid -type d \( -not -perm 777 -and -not -user "$USER_CS" \) -ls
    find /var/cache/pyramid -type f \( -not -perm 666 -and -not -user "$USER_CS" \) -ls
fi

echo ""
echo "***********************************************************************"
echo " Сonfiguration archiving..."
echo "***********************************************************************"

tar -zcf pyrconfig.tar.gz /etc/${PYRAMID_DISTR}-* /etc/systemd/system/Pyramid* && echo SUCCESS || echo FAIL

echo "***********************************************************************"