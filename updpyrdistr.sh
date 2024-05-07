#!/bin/bash
# Скрипт для массового обновления пакетов Пирамиды. Должен лежать в одной папке с пакетами.

if [ "$(id -u)" != 0 ]; then
  echo "This script must be run as root. 'sudo $0'"
  exit 1
fi

for file in ./pyramid-control*.deb
do
  if [ ! -e "$file" ]
  then
    echo "$0 must be in folder with distribution!"
    exit 1
  fi
done

if which apt &> /dev/null;
then
    PACKET_MANAGER_COMMAND="apt install"
    PACKET_MANAGER_CHECK_CMD="dpkg-query -l"
    APT_OPT="grep ii"
else
    PACKET_MANAGER_COMMAND="yum install"
    PACKET_MANAGER_CHECK_CMD="rpm -qa -last"
    APT_OPT="cat"
fi 

if $PACKET_MANAGER_CHECK_CMD "pyramid-control*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-control*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-collector*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-collector*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-user-web*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-user-web*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-client-web*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-client-web*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-integration*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-integration*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-csproxy*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-csproxy*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-usv*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-usv*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-opc-server*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-opc-server*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-opc-client*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-opc-client*.deb
fi

if $PACKET_MANAGER_CHECK_CMD "pyramid-fias*" | $APT_OPT &> /dev/null;
then
  $PACKET_MANAGER_COMMAND ./pyramid-fias*.deb
fi

$PACKET_MANAGER_CHECK_CMD "pyramid-*" | $APT_OPT