#!/bin/bash

PATH_TO_RDE=$1

/usr/lib/pyramid-control/RDMigrate I -R -F="$PATH_TO_RDE" -HISTORY=1



function input_yes_no() {
    while read -r answer; do
        case "${answer}" in
        "Yes" | "y" | "yes" | "")
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

# if input_yes_no ; then
#     echo "yes"
# else
#     echo "no"
# fi