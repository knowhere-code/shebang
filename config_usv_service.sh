#!/bin/bash

if [ "$(id -u)" == 0 ]; then
  echo "This script must be run by user of UsvTimeService!"
  exit
fi

PATH_TO_USV_TIME_SET="/var/cache/pyramid/UsvTime.settings"

if [ -f "$PATH_TO_USV_TIME_SET" ]
then
    USER_OWNER=$(stat -c '%U' $PATH_TO_USV_TIME_SET)
    if [ "$USER_OWNER" != "$USER" ]; then
        echo "This script must be run by user ($USER_OWNER) of UsvTimeService!"
        exit 1
    fi
else
    echo "$PATH_TO_USV_TIME_SET not found. You must execute: sudo UsvTimeService --start and sudo UsvTimeService --stop"
    exit 1
fi

USV_TYPE="Usv3"
USV_PASS="001234"

echo "Select type of USV ($USV_TYPE):"
select opt in "Usv3" "Usv2"; do
    if [ -n "$opt" ]; then
        echo "You have chosen $opt"
        USV_TYPE=$opt
        break
    elif [ -z "$opt" ]; then
        echo "You have chosen $USV_TYPE"
        break
    else
        echo "Invalid choice. Please select type of USV again!"
    fi
done

if [ $USV_TYPE = "Usv2" ]; then

fi





cat << EOF > /var/cache/pyramid/UsvTime.settings
<UsvSettings>
  <CultureCode>ru-RU</CultureCode>
  <UsvType>$USV_TYPE</UsvType>
  <UsvCom>/dev/ttyS0</UsvCom>
  <UsvLogin>
  </UsvLogin>
  <UsvPassword>001234</UsvPassword>
  <UsvAutoSynchro>1</UsvAutoSynchro>
  <UsvCheckStatus>1</UsvCheckStatus>
  <UsvSynchroPeriod>3600</UsvSynchroPeriod>
  <UsvMaxDiffDateTime>5</UsvMaxDiffDateTime>
  <UsvMinCorrectionLimit>1</UsvMinCorrectionLimit>
  <UsvMaxCorrectionLimit>1800</UsvMaxCorrectionLimit>
  <PyramidRegisterEvents>0</PyramidRegisterEvents>
  <PyramidControlServiceHost>127.0.0.1</PyramidControlServiceHost>
  <PyramidControlServicePort>8000</PyramidControlServicePort>
</UsvSettings>
EOF