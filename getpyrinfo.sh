#!/bin/bash
# Выдать скрипту права sudo chmod +x getpyrinfo.sh
# Запускать командой sudo ./getpyrinfo.sh &> getpyrinfo.log
# На выходе архив с конфигурацией pyrconfig.tar.gz и лог getpyrinfo.log

PATH_CS=/usr/lib/pyramid-control
PATH_UWEB=/usr/lib/pyramid-user-web
PATH_CWEB=/usr/lib/pyramid-client-web
PATH_COL=/usr/lib/pyramid-collector
PATH_FIAS=/usr/lib/pyramid-fias
PATH_INTER=/usr/lib/pyramid-integration
PATH_USV=/usr/lib/pyramid-usv
PATH_COPC=/usr/lib/pyramid-opc-client
PATH_SOPC=/usr/lib/pyramid-opc-server
PATH_CSPROX=/usr/lib/pyramid-csproxy

PATH_CS_NET=/usr/lib/pyrnet-control
PATH_UWEB_NET=/usr/lib/pyrnet-user-web
PATH_CWEB_NET=/usr/lib/pyrnet-client-web
PATH_COL_NET=/usr/lib/pyrnet-collector
PATH_FIAS_NET=/usr/lib/pyrnet-fias
PATH_INTER_NET=/usr/lib/pyrnet-integration
PATH_USV_NET=/usr/lib/pyrnet-usv
PATH_COPC_NET=/usr/lib/pyrnet-opc-client
PATH_SOPC_NET=/usr/lib/pyrnet-opc-server
PATH_CSPROX_NET=/usr/lib/pyrnet-csproxy

PYRAMID_DISTR=pyramid
CS_STATUS=0

#
# Information
#
echo "***********************************************************************"
echo " Quick get Pyramid 2.0 information script start..."
echo "***********************************************************************"

if [ -d $PATH_CS_NET ] || [ -d $PATH_COL_NET ] || [ -d $PATH_UWEB_NET ];
then
    PYRAMID_DISTR=pyrnet
fi

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

if [ -e "/etc/astra_version" ]
then
    echo "AstraLinux version: $(cat /etc/astra_version)"
    echo ""
fi

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

if [ -n "$(command -v sestatus)" ];
then    
    sestatus
fi

echo ""
echo "***********************************************************************"
echo " Firewall info"
echo "***********************************************************************"

if [ -n "$(command -v firewall-cmd)" ];
then    
    firewall-cmd --state
fi

if [ -n "$(command -v ufw)" ];
then    
    ufw status
fi

echo ""
echo "***********************************************************************"
echo " Pyramid intalled packages"
echo "***********************************************************************"

if [ -d $PATH_CS ] || [ -d $PATH_CS_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-control"
    CS_STATUS=1
fi

if [ -d $PATH_UWEB ] || [ -d $PATH_UWEB_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-user-web"
fi

if [ -d $PATH_CWEB ] || [ -d $PATH_CWEB_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-client-web"
fi

if [ -d $PATH_COL ] || [ -d $PATH_COL_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-collector"
fi

if [ -d $PATH_FIAS ] || [ -d $PATH_FIAS_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-fias"
fi

if [ -d $PATH_INTER ] || [ -d $PATH_INTER_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-integration"
fi

if [ -d $PATH_USV ] || [ -d $PATH_USV_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-usv"
fi

if [ -d $PATH_CSPROX ] || [ -d $PATH_CSPROX_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-csproxy"
fi

if [ -d $PATH_COPC ] || [ -d $PATH_COPC_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-opc-client"
fi

if [ -d $PATH_SOPC ] || [ -d $PATH_SOPC_NET ];
then
    echo "Installed ${PYRAMID_DISTR}-control"
fi

echo ""

# альтернативный способ проверки 
# if which rpm &> /dev/null; then
#     echo "rpm установлен!"
# fi

if [ -n "$(command -v rpm)" ];
then
    rpm -qa -last "${PYRAMID_DISTR}*"
fi

if [ -n "$(command -v dpkg-query)" ];
then
    dpkg-query -l "${PYRAMID_DISTR}*" | grep ii | awk '{print $1, $2, $3}'
fi

echo ""
echo "***********************************************************************"
echo " Kaspersky"
echo "***********************************************************************"

if [ -d /opt/kaspersky ]
then
    echo "Installed Kaspersky!"
fi

echo ""
echo "***********************************************************************"
echo " Pyramid services running"
echo "***********************************************************************"

systemctl --type=service --state=running | grep Pyramid

echo ""
echo "***********************************************************************"
echo " СontrolService run by user info"
echo "***********************************************************************"

TEMPLATE_CS="ControlService"
PID=$(pgrep -i "${TEMPLATE_CS}*")
if [ -n "$PID" ]
then
    USER_CS=$(ps -o user= -p "$PID")
    USER_GR="$(groups "$USER_CS")"
else
    CS_STATE="$TEMPLATE_CS is not runnining or installed!"
fi

echo "$CS_STATE"
if [ -z "$CS_STATE" ]
then
    echo "СontrolService (pid=$PID) run by $USER_GR"
    echo ""
fi

echo ""
echo "***********************************************************************"
echo " СollectorService run by user info"
echo "***********************************************************************"

TEMPLATE_COL="CollectorService"
PID=$(pgrep -i "${TEMPLATE_COL}*")
if [ -n "$PID" ]
then
    USER_COL=$(ps -o user= -p "$PID")
    USER_GR_COL="$(groups "$USER_COL")"
else
    COL_STATE="Collector Service is not runnining or installed!"
fi

echo "$COL_STATE"
if [ -z "$COL_STATE" ]
then
    echo "$TEMPLATE_COL (pid=$PID) run by $USER_GR_COL"
fi

echo ""
echo "***********************************************************************"
echo " Astra Linux permissions"
echo "***********************************************************************"

if [ -n "$USER_CS" ] && [ -n "$(command -v pdpl-user)" ]
then
    ASTRA_USER_PERM=$(pdpl-user "$USER_CS")
fi

if [ -n "$ASTRA_USER_PERM" ]
then
    echo "ASTRA USER ($USER_CS) MAX PERMISSION (MUST BE 0:63:0x0:0x0):"
    echo "$ASTRA_USER_PERM"
    echo ""
    echo "\"Command to set max permissions: sudo pdpl-user -i 63 $USER_CS\""
fi
echo ""

if [ -n "$(command -v astra-modeswitch)" ]
then
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

if [ -n "$USER_CS" ] && [ $CS_STATUS -eq 1 ] 
then
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

