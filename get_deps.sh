#!/bin/bash

DEB="$1"

# Проверка аргумента
if [ -z "$DEB" ]; then
    echo "Использование: $0 <файл.deb>"
    exit 1
fi

# Проверка существования файла
if [ ! -f "$DEB" ]; then
    echo "Ошибка: Файл '$DEB' не найден"
    exit 1
fi

# Функция получения полного адреса репозитория
get_repo_url() {
    local pkg="$1"
    
    # Проверяем установлен ли пакет
    if ! dpkg-query -W "$pkg" &>/dev/null; then
        echo "не установлен"
        return
    fi
    
    # Получаем установленную версию
    local installed_version=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null)
    
    # Получаем вывод apt-cache policy
    local policy=$(apt-cache policy "$pkg" 2>/dev/null)
    
    # Ищем строку с установленной версией и берем следующий за ней URL
    # У вас версия помечена как "*** 2.28-10+deb10u2+ci202309131632+astra7 100"
    # Или просто "2.28-10+deb10u2+ci202309131632+astra7 100"
    
    # Ищем версию в таблице
    local repo_url=$(echo "$policy" | grep -B1 "$installed_version" | head -1 | grep -E "https?://" | sed 's/^[ \t]*//')
    
    # Если не нашли, ищем по числовому коду (100, 900 и т.д.)
    if [ -z "$repo_url" ]; then
        # Находим строку с версией и числом (например "2.28-10+deb10u2+ci202309131632+astra7 100")
        local version_line=$(echo "$policy" | grep "$installed_version" | grep -E "[0-9]+$" | head -1)
        if [ -n "$version_line" ]; then
            # Получаем число (100, 900 и т.д.)
            local code=$(echo "$version_line" | grep -oE '[0-9]+$')
            # Ищем URL с этим кодом
            repo_url=$(echo "$policy" | grep -B1 "$code " | head -1 | grep -E "https?://" | sed 's/^[ \t]*//')
        fi
    fi
    
    # Если нашли URL
    if [ -n "$repo_url" ]; then
        echo "$repo_url"
    else
        # Проверяем, не установлен ли вручную
        local status_line=$(echo "$policy" | grep "/var/lib/dpkg/status" | head -1)
        if [ -n "$status_line" ]; then
            echo "установлен вручную (dpkg -i)"
        else
            echo "источник не определён"
        fi
    fi
}

echo "=== ЗАВИСИМОСТИ ПАКЕТА ==="
echo "Файл: $DEB"
echo ""

# Получаем зависимости
DEPS=$(dpkg-deb -f "$DEB" Depends 2>/dev/null | tr ',' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -v '^$')

if [ -z "$DEPS" ]; then
    echo "Пакет не имеет зависимостей"
    exit 0
fi

echo "$DEPS"
echo ""

echo "=== ПРОВЕРКА УСТАНОВЛЕННЫХ ВЕРСИЙ ==="
echo ""

INSTALLED=0
MISSING=0

while IFS= read -r dep_line; do
    [ -z "$dep_line" ] && continue
    
    # Проверяем альтернативы
    if [[ "$dep_line" == *"|"* ]]; then
        echo "📌 Альтернативные зависимости: $dep_line"
        
        IFS='|' read -ra ALTS <<< "$dep_line"
        alt_installed=""
        
        for alt in "${ALTS[@]}"; do
            alt=$(echo "$alt" | sed 's/^[ \t]*//;s/[ \t]*$//')
            PKG_NAME=$(echo "$alt" | sed 's/([^)]*)//g' | awk '{print $1}')
            CONSTRAINT=$(echo "$alt" | grep -o '([^)]*)' | sed 's/[()]//g')
            SYS_VERSION=$(dpkg-query -W -f='${Version}' "$PKG_NAME" 2>/dev/null)
            
            if [ -n "$SYS_VERSION" ]; then
                alt_installed="$alt"
                REPO_URL=$(get_repo_url "$PKG_NAME")
                echo "   ✅ $PKG_NAME $CONSTRAINT"
                echo "      ↳ версия: $SYS_VERSION"
                echo "      ↳ репозиторий: $REPO_URL"
                ((INSTALLED++))
                break
            else
                echo "   ❌ $alt: НЕ УСТАНОВЛЕН"
            fi
        done
        
        if [ -z "$alt_installed" ]; then
            ((MISSING++))
        fi
        echo ""
    else
        # Обычная зависимость
        PKG_NAME=$(echo "$dep_line" | sed 's/([^)]*)//g' | awk '{print $1}')
        CONSTRAINT=$(echo "$dep_line" | grep -o '([^)]*)' | sed 's/[()]//g')
        SYS_VERSION=$(dpkg-query -W -f='${Version}' "$PKG_NAME" 2>/dev/null)
        
        if [ -n "$SYS_VERSION" ]; then
            REPO_URL=$(get_repo_url "$PKG_NAME")
            echo "✅ $PKG_NAME $CONSTRAINT"
            echo "   ↳ версия: $SYS_VERSION"
            echo "   ↳ репозиторий: $REPO_URL"
            ((INSTALLED++))
        else
            echo "❌ $dep_line: НЕ УСТАНОВЛЕН"
            ((MISSING++))
        fi
        echo ""
    fi
done <<< "$DEPS"

echo "=== ИТОГО ==="
echo "Установлено: $INSTALLED"
echo "Отсутствует: $MISSING"