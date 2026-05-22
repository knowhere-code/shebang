#!/bin/bash
# TUI cкрипт для установки пакетов Пирамиды. Скрипт должен находиться в одной папке с пакетами.

# Проверка прав пользователя
if [ "$(id -u)" != 0 ]; then
  echo "${TEXT_need_root} 'sudo $0'"
  sudo "$0" "$@"
  exit
fi

WIDTH=80
HEIGHT=20

# Exit codes.
SUCCESS=0
FAILURE=1

localize() {
    if test "$LANG" = "ru_RU.UTF-8" || test "$LANG" = "ru_RU.utf8"; then
        PRODUCT_NAME="Пирамида 2.0"
	TITLE="Установщик ${PRODUCT_NAME} beta"
	BUTTON_next="Далее"
	BUTTON_exit="Выход"
	BUTTON_back="Назад"

	SHORT_cs="Служба управления"
	SHORT_col="Служба автоматизированного сбора данных"
	SHORT_uw="Корпоративный веб-сервер"
	SHORT_cw="Публичный веб-сервер"
	SHORT_csp="Служба представления данных"
	SHORT_int="Служба информобмена"
	SHORT_usv="Служба синхронизации времени"
	SHORT_opcc="Служба OPC UA клиентов"
	SHORT_opcs="Служба OPC UA серверов"
	TEXT_need_root="
Для работы установщика требуются привилегии администратора"
	TEXT_main_menu="Добро пожаловать в мастер установки ${PRODUCT_NAME}

Мастер установки позволит установить, обновить ${PRODUCT_NAME} с компьютера. Нажмите $BUTTON_next для продолжения или $BUTTON_exit для выхода из мастера установки."

	TEXT_update_confirmation_tail="Нажмите $BUTTON_next, чтобы начать обновление. Чтобы вернуться и изменить настройки, нажмите $BUTTON_back."
	TEXT_createdb_confirmation_tail="Нажмите $BUTTON_next, чтобы запустить скрипт создание базы данных Postgres. Чтобы вернуться и изменить настройки, нажмите $BUTTON_back."
	TEXT_select_packages="Выберите набор для установки.

Не устанавливайте пакеты без необходимости: это усложнит настройку и может снизить производительность."

	TEXT_license_ok="Лицензия успешно проверена"
	TEXT_license_bad="Ошибка проверки лицензии, ключи не найдены. Ключи должны лежать в одной папке с дистрибутивами."
	TEXT_installed_pyr="Службы ${PRODUCT_NAME} уже установлены. Попробуйте выполнить обновления"
	TEXT_distr_pyr="Не найдены пакеты ${PRODUCT_NAME}! Установщик должен запускаться из папки с дистрибутивами"
	TEXT_choose_activity="Выберите операцию, которую нужно выполнить."
    else	
		PRODUCT_NAME="Pyramid 2.0"
		TITLE="${PRODUCT_NAME} Setup beta"
		BUTTON_next="Next"
		BUTTON_exit="Exit"
		BUTTON_back="Back"
		TEXT_installed_pyr="Pyramid services are already installed! Try running the update script"
    fi
}

test_whiptail_and_scripts() {
    if ! command -v whiptail >/dev/null 2>&1 ; then
        echo "Error: whiptail wasn't found" >&2
        if [ -f /etc/debian_version ] ||
           [ -f /etc/mcst_version ] ||
            grep Ubuntu /etc/lsb-release >/dev/null 2>&1
        then
            echo "Please run 'sudo apt-get install whiptail'" >&2
        elif [ -f /etc/altlinux-release ] ; then
            echo "Please run 'sudo apt-get install newt52'" >&2
        else
            echo "Please run 'sudo yum install newt'" >&2
        fi
        exit "${FAILURE}"
    fi
	if ! ls ./pyrinstaller.sh ./pyrupdater.sh > /dev/null 2>&1 ; then
        echo "Error: necessary scripts pyrinstaller.sh and pyrupdater.sh were not found"
        exit "${FAILURE}"
    fi
}

test_acl(){
	if ! command -v setfacl >/dev/null 2>&1 ; then
        echo "Error: acl wasn't found" >&2
        if [ -f /etc/debian_version ] ||
           [ -f /etc/mcst_version ] ||
            grep Ubuntu /etc/lsb-release >/dev/null 2>&1
        then
            echo "Please run 'sudo apt install acl'" >&2
        elif [ -f /etc/altlinux-release ] ; then
            echo "Please run 'sudo apt-get install acl'" >&2
        else
            echo "Please run 'sudo yum install acl'" >&2
        fi
        exit "${FAILURE}"
    fi
}

check_license() {
    if ls ./p20.* &> /dev/null; then
    	$TEXT_license_ok
    else
		whiptail --title  "$TITLE" --msgbox  "${TEXT_license_bad}." "${HEIGHT}" "${WIDTH}"
		main_menu
    fi
}

check_installed_pyr() {
	if ls /etc/systemd/system/Pyramid* &> /dev/null; then
		whiptail --title  "$TITLE" --msgbox  "${TEXT_installed_pyr}." "${HEIGHT}" "${WIDTH}"
		main_menu
	fi
}

check_distr_pyr(){
	if ls ./pyrnet-* &> /dev/null || ls ./pyramid-* &> /dev/null; then
		echo "Пакеты для установки найдены!"
	else
		whiptail --title  "$TITLE" --msgbox "${TEXT_distr_pyr}." "${HEIGHT}" "${WIDTH}"
		exit "${FAILURE}"
	fi
}

notification() {
    whiptail --title "$TITLE" \
        --msgbox "Скрипт выполнен. Код ошибки ${script_status}. Для выхода в главное меню нажите Ok." \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"

		main_menu
}

update_notification(){
	if (whiptail --title  "$TITLE" --yes-button "$BUTTON_next" --no-button "$BUTTON_back" --yesno "$TEXT_update_confirmation_tail" "${HEIGHT}" "${WIDTH}") then
		bash ./pyrupdater.sh -y
		script_status="$?"
		press_anykey
		notification
	else
		main_menu
	fi
}

createdb_notification(){
	if (whiptail --title  "$TITLE" --yes-button "$BUTTON_next" --no-button "$BUTTON_back" --yesno "$TEXT_createdb_confirmation_tail" "${HEIGHT}" "${WIDTH}") then
		bash ./create_pgdb.sh
		script_status="$?"
		press_anykey
		notification
	else
		main_menu
	fi
}

press_anykey(){
	read -s -n 1 -p "Изучите лог на предмет ошибок! Для выхода в меню нажмите любую клавишу..."
	echo -e ""
}

install_pyr_menu(){
	DISTRPYR=$(whiptail --title "$TITLE" --checklist \
	"$TEXT_select_packages" "${HEIGHT}" "${WIDTH}" 9 \
	"ControlService" "$SHORT_cs" ON \
	"CollectorService" "$SHORT_col" ON \
	"PyramidUserWeb" "$SHORT_uw" ON \
	"PyramidClientWeb" "$SHORT_cw" OFF \
	"IntegrationService" "$SHORT_int" OFF \
	"CSProxyService" "$SHORT_csp" OFF \
	"UsvTimeService" "$SHORT_usv" OFF \
	"OpcUaClientsService" "$SHORT_opcc" OFF \
	"OpcUaServersService" "$SHORT_opcs" OFF 3>&1 1>&2 2>&3)
	
	if [ "$?" -eq "${SUCCESS}" ] && [ -n "$DISTRPYR" ]; then
		# eval "bash ./pyrinstaller.sh ${DISTRPYR}"
		echo "$DISTRPYR" | xargs bash ./pyrinstaller.sh
		script_status="$?"
		press_anykey	
		notification
	else
		main_menu
	fi
}

welcome_menu() {
    whiptail --title "$TITLE" \
        --yesno "$TEXT_main_menu" \
        --yes-button "$BUTTON_next" --no-button "$BUTTON_exit" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        exit "${SUCCESS}"
	fi
    main_menu
}

main_menu(){
	OPTION=$(whiptail --title "$TITLE" --menu "$TEXT_choose_activity" \
	--cancel-button "$BUTTON_exit" \
	"${HEIGHT}" "${WIDTH}" 3 --notags \
	"1" "Установка" \
	"2" "Обновление" \
	"3" "Создание БД PostgreSQL" 3>&1 1>&2 2>&3)
	
	if [ "$?" -eq "${SUCCESS}" ] ; then
		case "$OPTION" in
		"1") 
			check_license
			install_pyr_menu
		;;
		"2") 
			update_notification
		;;
		"3") 
			createdb_notification
		;;	
		esac
	
	else
		exit "${SUCCESS}"
	fi
}

main(){

	localize
	test_whiptail_and_scripts
	test_acl
	check_distr_pyr
	welcome_menu
}

main "$@"