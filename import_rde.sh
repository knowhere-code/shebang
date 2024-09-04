#!/bin/bash

PATH_TO_RDE=$1

/usr/lib/pyramid-control/RDMigrate I -R -F="$PATH_TO_RDE" -HISTORY=1

