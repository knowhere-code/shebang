#!/bin/bash

PATH_TO_SCRIPT=$1

[ -z "$PATH_TO_SCRIPT" ] || [ ! -f "$PATH_TO_SCRIPT" ] && echo "Path not found. sudo bash $0 /path/to/Last.rde" && exit 1

/usr/lib/pyramid-control/ObjStudioConsole -s "$PATH_TO_RDE" -l "ServiceCore"


