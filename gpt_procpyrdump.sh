#!/bin/bash
# This script monitors the memory usage of a process and creates a dump if the threshold is exceeded.

# Default value in megabytes
TRIGGER_RAM=2000
# Frequency of checking the process in seconds
CHECK_INTERVAL=5

# Validate arguments
if [[ -n "$1" ]]; then
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "The first argument must be a number!"
        exit 1
    fi
    TRIGGER_RAM=$1
fi

if [[ -n "$2" ]]; then
    if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "The second argument must be a number!"
        exit 1
    fi
    SRV_INDEX=$2
fi

# Set paths
PATH_CS_NET="/usr/lib/pyrnet-control"
PATH_COL_NET="/usr/lib/pyrnet-collector"
PYRAMID_DISTR="pyramid"

if [[ -d $PATH_CS_NET || -d $PATH_COL_NET ]]; then
    PYRAMID_DISTR="pyrnet"
fi

# Check dump configuration
if ! grep -q -e "COMPlus_DbgEnableMiniDump" -e "COMPlus_DbgMiniDumpType" /etc/environment; then
    echo "Dump creation is not configured in /etc/environment"
    exit 1
fi

# Select service
case $SRV_INDEX in
    1) TEMPLATE="ControlService" ;;
    2) TEMPLATE="CollectorService" ;;
    *)
        PS3='Select Service: '
        select TEMPLATE in "ControlService" "CollectorService"; do
            break
        done
        ;;
esac

# Get process PID
PID=$(pgrep -i "${TEMPLATE}*")
if [[ -z "$PID" ]]; then
    echo "$TEMPLATE is not running or installed!"
    exit 1
fi

echo ""
echo "Start Date:                             $(date)"
echo "Process Name:                           $TEMPLATE (PID=$PID)"
echo "Memory Threshold:                       >= $TRIGGER_RAM MB"
echo ""
echo "Press Ctrl-C to end monitoring without terminating the process."
trap 'echo "$(date) Terminated"; exit 1' SIGINT SIGHUP

# Monitor memory and create dump
while true; do
    RAM=$(ps -o rss= --pid "$PID" | awk '{print int($1/1024)}')
    if [[ "$RAM" -ge "$TRIGGER_RAM" ]]; then
        echo "Threshold reached: Memory usage $RAM MB on process ID: $PID"
        /usr/lib/${PYRAMID_DISTR}-control/createdump --full "$PID" || /usr/lib/${PYRAMID_DISTR}-collector/createdump --full "$PID"
        break
    elif ! pgrep -i "${TEMPLATE}*" &> /dev/null; then
        echo "$TEMPLATE is not running ($(date))"
        exit 1
    fi
    sleep $CHECK_INTERVAL
done
