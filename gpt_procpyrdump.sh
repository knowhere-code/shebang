#!/bin/bash
# Скрипт для мониторинга памяти процесса и создания дампа при превышении порога.
# Предварительно необходимо включить возможность снятия дампов.

# Значение по умолчанию в мегабайтах
TRIGGER_RAM=2000
# Частота проверки процесса в секундах
CHECK_INTERVAL=5

# Проверка аргументов
if [[ -n "$1" ]]; then
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Первый аргумент должен быть числом!"
        exit 1
    fi
    TRIGGER_RAM=$1
fi

if [[ -n "$2" ]]; then
    if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Второй аргумент должен быть числом!"
        exit 1
    fi
    SRV_INDEX=$2
fi

# Установление путей
PATH_CS_NET="/usr/lib/pyrnet-control"
PATH_COL_NET="/usr/lib/pyrnet-collector"
PYRAMID_DISTR="pyramid"

if [[ -d $PATH_CS_NET || -d $PATH_COL_NET ]]; then
    PYRAMID_DISTR="pyrnet"
fi

# Проверка конфигурации дампов
if ! grep -q -e "COMPlus_DbgEnableMiniDump" -e "COMPlus_DbgMiniDumpType" /etc/environment; then
    echo "Создание дамп-файлов не настроено в /etc/environment"
    exit 1
fi

# Выбор сервиса
case $SRV_INDEX in
    1) TEMPLATE="ControlService" ;;
    2) TEMPLATE="CollectorService" ;;
    *)
        PS3='Выберите сервис: '
        select TEMPLATE in "ControlService" "CollectorService"; do
            break
        done
        ;;
esac

# Получение PID процесса
PID=$(pgrep -i "${TEMPLATE}*")
if [[ -z "$PID" ]]; then
    echo "$TEMPLATE не запущен или не установлен!"
    exit 1
fi

echo ""
echo "Дата начала:                             $(date)"
echo "Имя процесса:                            $TEMPLATE (PID=$PID)"
echo "Порог памяти:                            >= $TRIGGER_RAM MB"
echo ""
echo "Для завершения мониторинга нажмите Ctrl-C."
trap 'echo "$(date) Завершено"; exit 1' SIGINT SIGHUP

# Мониторинг памяти и создание дампа
while true; do
    RAM=$(ps -o rss= --pid "$PID" | awk '{print int($1/1024)}')
    if [[ "$RAM" -ge "$TRIGGER_RAM" ]]; then
        echo "Порог достигнут: Использование памяти $RAM MB процессом ID: $PID"
        /usr/lib/${PYRAMID_DISTR}-control/createdump --full "$PID" || /usr/lib/${PYRAMID_DISTR}-collector/createdump --full "$PID"
        break
    elif ! pgrep -i "${TEMPLATE}*" &> /dev/null; then
        echo "$TEMPLATE не запущен ($(date))"
        exit 1
    fi
    sleep $CHECK_INTERVAL
done