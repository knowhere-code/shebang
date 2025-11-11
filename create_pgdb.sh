#!/bin/bash
set -euo pipefail

# ========================================
# Параметры
# ========================================
DB_SUPERUSER="postgres"        # Суперпользователь PostgreSQL
DB_NAME="pyramid"              # Имя базы данных
DB_USER="pyramid"              # Имя создаваемого пользователя
DB_PASS="1234"                 # Пароль пользователя

# ========================================
# Проверка наличия PostgreSQL
# ========================================
if ! psql -V &>/dev/null; then
    echo "❌ Не найден клиент psql PostgreSQL."
    exit 1
fi
# ========================================
# Проверка соединения
# ========================================
echo "Проверяем подключение к PostgreSQL как $DB_SUPERUSER..."
sudo -u $DB_SUPERUSER psql -c '\q'|| {
    echo "❌ Ошибка подключения к PostgreSQL под пользователем $DB_SUPERUSER"
    echo "У пользователя $DB_SUPERUSER в /etc/postgresql/Версия/main/pg_hba.conf должен быть метод аунтификации peer"
    echo "# TYPE  DATABASE     USER        ADDRESS      METHOD"
    echo "  local   all       postgres                   peer"
    exit 1
}
echo "Подключение успешно."

# ========================================
# Создание пользователя (если нет)
# ========================================
echo "Проверяем наличие пользователя '$DB_USER'..."
sudo -u $DB_SUPERUSER psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
      RAISE NOTICE 'Создаю пользователя ${DB_USER}...';
      CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
   ELSE
      RAISE NOTICE 'Пользователь ${DB_USER} уже существует — пропускаем.';
   END IF;
END
\$\$;
SQL

# ========================================
# Создание базы данных (если нет)
# ========================================
echo "Проверяем наличие базы '$DB_NAME'..."
DB_EXISTS=$(sudo -u $DB_SUPERUSER psql -t -c "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'")

if [ -z "$DB_EXISTS" ]; then
    echo "Создаю базу данных ${DB_NAME}..."
    sudo -u $DB_SUPERUSER psql -c "CREATE DATABASE ${DB_NAME} WITH ENCODING 'utf8' OWNER ${DB_USER};"
else
    echo "База ${DB_NAME} уже существует — пропускаем."
fi

# ========================================
# Назначение прав
# ========================================
echo "Настраиваем права доступа в базе '$DB_NAME'..."

sudo -u $DB_SUPERUSER psql -d postgres -v ON_ERROR_STOP=1 <<SQL
-- Права на подключение к БД (выполняется в postgres)
REVOKE CONNECT ON DATABASE ${DB_NAME} FROM PUBLIC;
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_USER};
SQL

sudo -u $DB_SUPERUSER psql -d ${DB_NAME} -v ON_ERROR_STOP=1 <<SQL
-- Права на схему public (выполняется в конкретной БД)
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO ${DB_USER};
SQL

# ========================================
# Завершение
# ========================================
echo "Всё готово:"
echo "   • Пользователь: ${DB_USER}"
echo "   • База данных: ${DB_NAME}"
echo "   • Владелец базы: ${DB_USER}"
