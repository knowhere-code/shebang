#!/bin/bash

# Функция для ввода Да/Нет
function input_yes_no() {
    while read -r answer; do
        case "${answer,,}" in  # преобразование в нижний регистр для простоты
            "yes" | "y")
                return 0
                ;;
            "no" | "n" | "")
                return 1
                ;;
            *)
                echo "Введите 'y' или 'n': "
                ;;
        esac
    done
}

# Проверка на запуск от root и от правильного пользователя
if [ "$(id -u)" == 0 ]; then
    echo "Скрипт должен выполняться от пользователя UsvTimeService!"
    exit 1
fi

TEMPLATE_USV="UsvTime"
PID=$(pgrep -i "${TEMPLATE_USV}*")
if [ -n "$PID" ]; then
    echo "Останавливаем службу UsvTimeService..."
    sudo UsvTimeService --stop
fi

# Путь к файлу настроек
PATH_TO_USV_TIME_SET="/var/cache/pyramid/UsvTime.settings"
USER_OWNER=$(stat -c '%U' "$PATH_TO_USV_TIME_SET")
# Проверка существования файла настроек и пользователя-владельца
if [ -f "$PATH_TO_USV_TIME_SET" ]; then
    if [ "$USER_OWNER" != "$USER" ]; then
        echo "Скрипт должен выполняться от пользователя $USER_OWNER!"
        exit 1
    fi
else
    echo "Файл $PATH_TO_USV_TIME_SET не найден. Выполните: sudo UsvTimeService --start и sudo UsvTimeService --stop"
    exit 1
fi

# Установка значений по умолчанию
USV_TYPE="Usv3"
USV2_PASS="001234"
USVCOM="/dev/ttyS0"
IP="127.0.0.1"
REGEVENTS=0

# Выбор типа USV
echo "Выберите тип USV:"
select type in "Usv3" "Usv2"; do
    if [ -n "$type" ]; then
        USV_TYPE=$type
        echo "Вы выбрали $USV_TYPE"
        break
    else
        echo "Неверный выбор. Попробуйте снова."
    fi
done

# Запрос пароля для USV2, если выбран
if [ "$USV_TYPE" = "Usv2" ]; then
    read -rp "Введите пароль для USV2 (по умолчанию $USV2_PASS):" input_pass
    USV2_PASS="${input_pass:-$USV2_PASS}"
    echo "Вы ввели пароль $USV2_PASS"
fi

# Запрос имени порта
read -rp "Введите имя COM-порта (по умолчанию $USVCOM):" input_com
USVCOM="${input_com:-$USVCOM}"
echo "Вы выбрали $USVCOM"

# Регистрация событий в Pyramid
echo "Регистрировать события в Pyramid? (y/n)"
if input_yes_no; then
    REGEVENTS=1
    read -rp "Введите IP-адрес ControlService (по умолчанию $IP):" input_ip
    IP="${input_ip:-$IP}"

    # Проверка формата IP-адреса
    if ! [[ $IP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [[ $(echo "$IP" | awk -F '.' '{for(i=1;i<=4;i++) if($i>255) exit 1}') ]]; then
        echo "Неверный формат IP-адреса. Укажите правильный IP."
        exit 1
    fi
fi

# Запись настроек в файл
cat << EOF > "$PATH_TO_USV_TIME_SET"
<UsvSettings>
  <CultureCode>ru-RU</CultureCode>
  <UsvType>$USV_TYPE</UsvType>
  <UsvCom>$USVCOM</UsvCom>
  <UsvLogin></UsvLogin>
  <UsvPassword>$USV2_PASS</UsvPassword>
  <UsvAutoSynchro>1</UsvAutoSynchro>
  <UsvCheckStatus>1</UsvCheckStatus>
  <UsvSynchroPeriod>3600</UsvSynchroPeriod>
  <UsvMaxDiffDateTime>5</UsvMaxDiffDateTime>
  <UsvMinCorrectionLimit>1</UsvMinCorrectionLimit>
  <UsvMaxCorrectionLimit>1800</UsvMaxCorrectionLimit>
  <PyramidRegisterEvents>$REGEVENTS</PyramidRegisterEvents>
  <PyramidControlServiceHost>$IP</PyramidControlServiceHost>
  <PyramidControlServicePort>8000</PyramidControlServicePort>
</UsvSettings>
EOF

echo "Настройки UsvTimeService успешно сохранены. Запускаем службу."
sudo UsvTimeService --start