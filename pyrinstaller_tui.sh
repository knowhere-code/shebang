#!/bin/bash
# author: Ametov S.I.
# TUI script for installing Pyramid 2.0 Net packages. The script must be located in the same folder as the packages.


WIDTH=80
HEIGHT=20
HEIGHT_LOW=10	

# Exit codes.
SUCCESS=0
FAILURE=1

DB_NAME="pyramid" 
DB_USER="pyramid" 
DB_PASS="1234"

localize() {
    if test "$LANG" = "ru_RU.UTF-8" || test "$LANG" = "ru_RU.utf8"; then
		PRODUCT_NAME="Пирамида 2.0"
		TITLE="Установщик ${PRODUCT_NAME} beta"
		BUTTON_next="Далее"
		BUTTON_exit="Выход"
		BUTTON_back="Назад"
		MENU_install="Установка"
		MENU_update="Обновление"
		MENU_createdb="Создание базы данных PostgreSQL"
		SHORT_cs="Служба управления"
		SHORT_col="Служба автоматизированного сбора данных"
		SHORT_uw="Корпоративный веб-сервер"
		SHORT_cw="Публичный веб-сервер"
		SHORT_csp="Служба представления данных"
		SHORT_int="Служба информобмена"
		SHORT_usv="Служба синхронизации времени"
		SHORT_opcc="Служба OPC UA клиентов"
		SHORT_opcs="Служба OPC UA серверов"
		TEXT_main_menu="Добро пожаловать в мастер установки ${PRODUCT_NAME}

Мастер установки позволит установить, обновить ${PRODUCT_NAME} с компьютера. Нажмите $BUTTON_next для продолжения или $BUTTON_exit для выхода из мастера установки."

		TEXT_update_confirmation_tail="Нажмите $BUTTON_next, чтобы начать обновление. Чтобы вернуться и изменить настройки, нажмите $BUTTON_back."
		TEXT_createdb_confirmation_tail="Нажмите $BUTTON_next, чтобы запустить скрипт создания базы данных Postgres.
Чтобы вернуться и изменить настройки, нажмите $BUTTON_back.
"
		TEXT_ask_db_name="Введите имя базы данных:"
		TEXT_ask_db_user="Введите имя владельца базы данных:"
		TEXT_ask_db_pass="Введите пароль владельца базы данных:"
		TEXT_warn_createdb="Внимание! Скрипт должен быть запущен локально на сервере СУБД Postgres."
		TEXT_select_packages="Выберите набор для установки.

Не устанавливайте пакеты без необходимости и вне вашей лицензии - это усложнит настройку и может снизить производительность."

		TEXT_license_ok="Лицензионные ключи найдены."
		TEXT_license_bad="Ошибка проверки лицензии, ключи не найдены. Ключи должны лежать в одной папке с дистрибутивами."
		TEXT_installed_pyr="Службы ${PRODUCT_NAME} уже установлены. Попробуйте выполнить обновления."
		TEXT_distr_pyr="Не найдены пакеты ${PRODUCT_NAME}! Установщик должен запускаться из папки с дистрибутивами."
		TEXT_distr_ok="Дистрибутивы найдены."
		TEXT_choose_activity="Выберите операцию, которую нужно выполнить."
		TEXT_anykey="Изучите лог на предмет ошибок! Для выхода в меню нажмите любую клавишу..."
		TEXT_result_script="Скрипт выполнен. Для выхода в главное меню нажите Ok."
    else	
		PRODUCT_NAME="Pyramid 2.0"
		TITLE="${PRODUCT_NAME} Installer beta"
		BUTTON_next="Next"
		BUTTON_exit="Exit"
		BUTTON_back="Back"
		MENU_install="Installation"
		MENU_update="Update"
		MENU_createdb="Create PostgreSQL Database"
		SHORT_cs="Control Service"
		SHORT_col="Automated Data Collection Service"
		SHORT_uw="Corporate Web Server"
		SHORT_cw="Public Web Server"
		SHORT_csp="Data Presentation Service"
		SHORT_int="Information Exchange Service"
		SHORT_usv="Time Synchronization Service"
		SHORT_opcc="OPC UA Client Service"
		SHORT_opcs="OPC UA Server Service"
		TEXT_main_menu="Welcome to the ${PRODUCT_NAME} Setup Wizard
The setup wizard will help you install or update ${PRODUCT_NAME} on this computer. Click $BUTTON_next to continue or $BUTTON_exit to exit the setup wizard."
		TEXT_update_confirmation_tail="Click $BUTTON_next to start the update. To go back and change settings, click $BUTTON_back."
		TEXT_createdb_confirmation_tail="Press $BUTTON_next to run the Postgres database creation script. 
To go back and change the settings, press $BUTTON_back.
"
		TEXT_warn_createdb="Warning! The script must be run locally on the Postgres database server."
		TEXT_select_packages="Select the installation package set.
Do not install packages unless necessary: this may complicate configuration and reduce performance."
		TEXT_license_ok="License successfully verified."
		TEXT_license_bad="License verification failed, keys not found. The keys must be located in the same folder as the distributions."
		TEXT_distr_ok="Distribution packages found."
		TEXT_installed_pyr="${PRODUCT_NAME} services are already installed. Try performing an update."
		TEXT_distr_pyr="${PRODUCT_NAME} packages not found! The installer must be run from the distribution folder."
		TEXT_choose_activity="Select the operation to perform."
		TEXT_anykey="Check the log for errors! Press any key to return to the menu..."
		TEXT_result_script="Script executed. Error code ${script_status}. Press Ok to return to the main menu."
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
    	echo "$TEXT_license_ok"
    else
		whiptail --title  "$TITLE" --msgbox  "${TEXT_license_bad}" "${HEIGHT}" "${WIDTH}"
		main_menu
    fi
}

check_installed_pyr() {
	if ls /etc/systemd/system/Pyramid* &> /dev/null; then
		whiptail --title  "$TITLE" --msgbox  "${TEXT_installed_pyr}" "${HEIGHT}" "${WIDTH}"
		main_menu
	fi
}

check_distr_pyr(){
	if ls ./pyrnet-* &> /dev/null || ls ./pyramid-* &> /dev/null; then
		echo "$TEXT_distr_ok"
	else
		whiptail --title  "$TITLE" --msgbox "${TEXT_distr_pyr}" "${HEIGHT}" "${WIDTH}"
		exit "${FAILURE}"
	fi
}

noti_script_done() {
    whiptail --title "$TITLE" \
        --msgbox "${TEXT_result_script}" \
        "${HEIGHT_LOW}" "${WIDTH}"

		main_menu
}

update_notification(){
	if (whiptail --title  "$TITLE" --yes-button "$BUTTON_next" --no-button "$BUTTON_back" --yesno "$TEXT_update_confirmation_tail" "${HEIGHT}" "${WIDTH}") then
		bash ./pyrupdater.sh -y
		script_status="$?"
		press_anykey
		noti_script_done
	else
		main_menu
	fi
}

ask_db_name(){
	DB_NAME=$(whiptail --title  "$TITLE" --inputbox  "$TEXT_ask_db_name" "${HEIGHT_LOW}" "${WIDTH}" "$DB_NAME" 3>&1 1>&2 2>&3)
	
	if [ "$?" -eq "${SUCCESS}" ] ; then
		ask_db_user
	else
		main_menu
	fi
}

ask_db_user(){
	DB_USER=$(whiptail --title  "$TITLE" --inputbox  "$TEXT_ask_db_user" "${HEIGHT_LOW}" "${WIDTH}" "$DB_USER" 3>&1 1>&2 2>&3)
	
	if [ "$?" -eq "${SUCCESS}" ] ; then
		ask_db_pass
	else
		main_menu
	fi
}

ask_db_pass(){
	DB_PASS=$(whiptail --title  "$TITLE" --inputbox  "$TEXT_ask_db_pass" "${HEIGHT_LOW}" "${WIDTH}" "$DB_PASS" 3>&1 1>&2 2>&3)
	
	if [ "$?" -eq "${SUCCESS}" ] ; then
		createdb_notification
	else
		main_menu
	fi
}

echo_db_info(){

echo "
DB Name: $DB_NAME 
DB User: $DB_USER 
User Password: $DB_PASS"

}

warn_createdb(){
	whiptail --title  "$TITLE" --msgbox  "$TEXT_warn_createdb" 10 "${WIDTH}"
}

createdb_notification(){
	if (whiptail --title  "$TITLE" --yes-button "$BUTTON_next" --no-button "$BUTTON_back" --yesno "$TEXT_createdb_confirmation_tail $(echo_db_info)" "${HEIGHT}" "${WIDTH}") then
		bash ./create_pgdb.sh "${DB_NAME}" "${DB_USER}" "${DB_PASS}"
		script_status="$?"
		press_anykey
		noti_script_done
	else
		main_menu
	fi
}

press_anykey(){
	read -r -s -n 1 -p "${TEXT_anykey}"
	echo
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
		noti_script_done
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
	"1" "$MENU_install" \
	"2" "$MENU_update" \
	"3" "$MENU_createdb" 3>&1 1>&2 2>&3)
	
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
			warn_createdb 
			ask_db_name	
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

if [ "$(id -u)" != 0 ]; then
  echo "Administrator privileges are required to run the installer. 'sudo $0'"
  sudo "$0" "$@"
  exit
fi

main "$@"