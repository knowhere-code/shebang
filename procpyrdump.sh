#!/bin/bash
# Предварительно нужно включить возможность снятия дампов в linux, для ASTRA Linux отдельная инструкция дополнительно:
# http://support.sicon.ru/mw/index.php/%D0%9F%D0%B8%D1%80%D0%B0%D0%BC%D0%B8%D0%B4%D0%B0_2.0#%D0%A1%D0%BD%D1%8F%D1%82%D0%B8%D0%B5_%D0%B4%D0%B0%D0%BC%D0%BF%D0%BE%D0%B2

# Выдать скрипту права sudo chmod 777 procpyrdump.sh
# Запускать командой под пользователем под которым работает сервис Пирамиды: ./procpyrdump.sh 3000
# где первый аргумент 3000 это кол-во памяти процесса в мегабайтах, при котором нужно создать дамп, если не задавать, то значение по умолчанию в TRIGGER_RAM 
# Можно запускать в фоновом режиме командой: 
# nohup ./procpyrdump.sh 3000 1 >> procpyrdump.log &
# где второй аргумент это индекс сервиса: 1 - ControlService; 2 - CollectorService

# Значение по умолчанию в мегабайтах
TRIGGER_RAM=2000

# Частота в сек, проверки процесса
SEC=5 

if [ -n "$1" ]
then
    case $1 in
        ''|*[!0-9]*) 
        echo "$1 Command line arguments are incorrect!"
        exit 1 
        ;;
        *) TRIGGER_RAM=$1 
        ;;
    esac
fi

if [ -n "$2" ]
then
    case $2 in
        ''|*[!0-9]*) 
        echo "$2 Command line arguments are incorrect!"
        exit 1 
        ;;
        *) SRV_INDEX=$2 
        ;;
    esac
fi

PATH_CS_NET=/usr/lib/pyrnet-control
PATH_COL_NET=/usr/lib/pyrnet-collector

PYRAMID_DISTR=pyramid

if [ -d $PATH_CS_NET ] || [ -d $PATH_COL_NET ];
then
    PYRAMID_DISTR=pyrnet
fi

echo "Press Ctrl-C to end monitoring without terminating the process(es)."
trap 'echo "$(date) Terminated"; exit 1' SIGINT SIGHUP

case $SRV_INDEX in
    "")
    PS3='Select Service: '
    select TEMPLATE in "ControlService" "CollectorService" 
    do
        break
    done
    ;;
    1) 
    TEMPLATE=ControlService 
    ;;
    2) 
    TEMPLATE=CollectorService
    ;;
    *) 
    echo "Command line arguments are incorrect!"
    exit 1
    ;;
esac

if [[ $(grep -e "COMPlus_DbgEnableMiniDump" -e "COMPlus_DbgMiniDumpType" /etc/environment) == "" ]]
then
    echo "Creation of dump files is not configured in /etc/environment"
    exit 1
fi

PID=$(pgrep -i "${TEMPLATE}*")
if [ -n "$PID" ]
then
    echo ""
    echo "Start Date:                             $(date)"
    echo "Process Name:                           $TEMPLATE (PID=$PID)"
    echo "Commit Threshold:                       >= $TRIGGER_RAM MB"
    echo ""
    while true
    do
        RAM=$(ps -o rss --pid "$PID" | awk '{$1/=1024;printf "%d",$1}')
        if [ "$RAM" -ge "$TRIGGER_RAM" ]
        then
            echo "Trigger: Commit usage: $RAM MB on process ID: $PID"
            /usr/lib/${PYRAMID_DISTR}-control/createdump --full "$PID" || /usr/lib/${PYRAMID_DISTR}-collector/createdump --full "$PID"
            break
        elif [ -z $(pgrep -i "${TEMPLATE}*") ]
        then
            echo "$TEMPLATE is not runnining ($(date))"
            exit 1
        fi
        sleep $SEC
    done
else
    echo "$TEMPLATE is not runnining or installed!"
fi