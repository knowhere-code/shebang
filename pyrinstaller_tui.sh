#!/bin/bash
# TUE cкрипт для установки пакетов Пирамиды. Скрипт должен находиться в одной папке с пакетами.

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
PACKAGES_NOT_AVAILABLE=2


localize() {
    if test "$LANG" = "ru_RU.UTF-8" || test "$LANG" = "ru_RU.utf8"; then
        PRODUCT_NAME="Пирамида 2.0"
	TITLE="Установщик ${PRODUCT_NAME} beta"
	BUTTON_next="Далее"
	BUTTON_exit="Выход"
	BUTTON_yes="Да"
	BUTTON_no="Нет"
	BUTTON_back="Назад"
	BUTTON_cancel="Отмена"
	BUTTON_enter_license="Ввести лицензию"
	BUTTON_later="Позже"
	BUTTON_install="Установить"
	BUTTON_reinstall="Переустановить"
	BUTTON_uninstall="Удалить"
	BUTTON_enter_serial="Ввести"
	BUTTON_select="Выбрать"
	BUTTON_add="Добавить"

	MENU_reinstall="Переустановить пакеты ${PRODUCT_NAME}"
	MENU_uninstall="Удалить пакеты ${PRODUCT_NAME}"

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
	TEXT_install_confirmation_head="Будут установлены:
"
	TEXT_install_confirmation_tail="Нажмите $BUTTON_install, чтобы начать установку. Чтобы вернуться и изменить настройки, нажмите $BUTTON_back."
	TEXT_update_confirmation_tail="Нажмите $BUTTON_next, чтобы начать обновление. Чтобы вернуться и изменить настройки, нажмите $BUTTON_back."
	TEXT_createdb_confirmation_tail="Нажмите $BUTTON_next, чтобы запустить скрипт создание базы данных Postgres. Чтобы вернуться и изменить настройки, нажмите $BUTTON_back."
	TEXT_select_packages="Выберите набор для установки.

Не устанавливайте пакеты без необходимости: это усложнит настройку и может снизить производительность."

	TEXT_reinstall_confirm="Переустановить ${PRODUCT_NAME}

Вы выбрали переустановить текущую установку ${PRODUCT_NAME}.

Нажмите $BUTTON_reinstall, чтобы переустановить ${PRODUCT_NAME}. Если вы хотите проверить или изменить настройки установки, нажмите $BUTTON_back."
	TEXT_uninstall_confirm="Удаление ${PRODUCT_NAME}

Вы выбрали удалить ${PRODUCT_NAME} с компьютера.

Нажмите $BUTTON_uninstall, чтобы удалить ${PRODUCT_NAME} с компьютера. Если вы хотите проверить или изменить настройки установки, нажмите $BUTTON_back."

	TEXT_license_ok="Лицензия успешно проверена"
	TEXT_license_bad="Ошибка проверки лицензии, ключ не найден"
	TEXT_installed_pyr="Службы ${PRODUCT_NAME} уже установлены. Попробуйте выполнить обновления"
	TEXT_distr_pyr="Не найдены пакеты ${PRODUCT_NAME}! Установщик должен запускаться из папки с дистрибутивами"
	
	TEXT_choose_activity="Выберите операцию, которую нужно выполнить."

	ERROR_root="Ошибка: этот скрипт надо запускать от имени root или с помощью sudo"
    else	
        PRODUCT_NAME="Pyramid 2.0"
	TITLE="${PRODUCT_NAME} Setup beta"
	BUTTON_next="Next"
	BUTTON_exit="Exit"
	BUTTON_yes="Yes"
	BUTTON_no="No"
	BUTTON_back="Back"
	BUTTON_cancel="Cancel"
	BUTTON_later="Later"
	BUTTON_install="Install"
	BUTTON_reinstall="Reinstall"
	BUTTON_uninstall="Uninstall"
	BUTTON_enter_serial="Enter"
	BUTTON_select="Select"
	BUTTON_add="Add"

	MENU_reinstall="Reinstall ${PRODUCT_NAME} packages"
	MENU_uninstall="Uninstall ${PRODUCT_NAME} packages"

	TEXT_installed_pyr="Pyramid services are already installed! Try running the update script"
    fi
}


test_whiptail() {
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
    ls ./p20.* &> /dev/null;
    if [ "$?" -eq "${SUCCESS}" ] ; then
        license_output="$TEXT_license_ok"
    else
		whiptail --title  "$TITLE" --msgbox  "${TEXT_license_bad}." "${HEIGHT}" "${WIDTH}"
		exit "${FAILURE}"
    fi
}

check_installed_pyr() {
	if ls /etc/systemd/system/Pyramid* &> /dev/null; then
		whiptail --title  "$TITLE" --msgbox  "${TEXT_installed_pyr}." "${HEIGHT}" "${WIDTH}"
		# todo переход в главное меню 
		main_menu2
	fi
}

check_distr_pyr(){
	if ls ./pyrnet-* &> /dev/null; then
		PYRAMID_DISTR=pyrnet
	elif ls ./pyramid-* &> /dev/null; then
		PYRAMID_DISTR=pyramid
	else
		whiptail --title  "$TITLE" --msgbox "${TEXT_distr_pyr}." "${HEIGHT}" "${WIDTH}"
		exit "${FAILURE}"
	fi
}


notification() {
    whiptail --title "$TITLE" \
        --msgbox "Скрипт выполнен" \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"

		main_menu2
    # if [ "${script_status}" -eq "${SUCCESS}" ] ; then
    #         exit ${SUCCESS}
    #     else
    #         main_menu2
    #     fi
}

update_notification(){
	if (whiptail --title  "$TITLE" --yes-button "$BUTTON_next" --no-button "$BUTTON_back" --yesno "$TEXT_update_confirmation_tail" "${HEIGHT}" "${WIDTH}") then
		bash ./pyrupdater.sh -y
		script_status="$?"
		press_anykey
		notification
	else
		main_menu2
	fi
}

createdb_notification(){
	if (whiptail --title  "$TITLE" --yes-button "$BUTTON_next" --no-button "$BUTTON_back" --yesno "$TEXT_createdb_confirmation_tail" "${HEIGHT}" "${WIDTH}") then
		bash ./create_pgdb.sh
		script_status="$?"
		press_anykey
		notification
	else
		main_menu2
	fi
}

press_anykey(){
	read -s -n 1 -p "Нажмите любую клавишу..."
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
	
	if [ "$?" -eq "${SUCCESS}" ] && [ -n "$DISTRPYR" ] ; then
		# eval "bash ./pyrinstaller.sh ${DISTRPYR}"
		echo "$DISTRPYR" | xargs bash ./pyrinstaller.sh
		script_status="$?"
		press_anykey	
		notification
	else
		main_menu2
	fi
}

main_menu1() {
    whiptail --title "$TITLE" \
        --yesno "$TEXT_main_menu" \
        --yes-button "$BUTTON_next" --no-button "$BUTTON_exit" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        exit "${SUCCESS}"
	fi
    main_menu2
}

main_menu2(){
	OPTION=$(whiptail --title  "$TITLE" --menu  "$TEXT_choose_activity" "${HEIGHT}" "${WIDTH}" 3 \
	"1" "Установка" \
	"2" "Обновление" \
	"3" "Создание БД PostgreSQL" 3>&1 1>&2 2>&3)
	
	if [ "$?" -eq "${SUCCESS}" ] ; then
		case "$OPTION" in
		"1") 
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
	test_whiptail
	test_acl
	check_license
	check_distr_pyr
	main_menu1
}

main "$@"