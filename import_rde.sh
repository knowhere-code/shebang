#!/bin/bash

PATH_TO_RDE=$1
WR=
HISTORY=

function input_yes_no() {
    while read -r answer; do
        case "${answer}" in
        "Yes" | "y" | "yes")
            return 0
            ;;
        "No" | "n" | "no")
            return 1
            ;;
        *)
            echo "Please enter 'y' or 'n': "
            ;;
        esac
    done
}

[ -z "$PATH_TO_RDE" ] && echo "Path not found. sudo bash $0 /path/to/Last.rde" && exit 1
[ "$2" = "-h" ] && HISTORY="-HISTORY=1"
echo "Clear BD?"
if input_yes_no ; then
    WR="-R"
fi
/usr/lib/pyramid-control/RDMigrate I -F="$PATH_TO_RDE" $HISTORY $WR


