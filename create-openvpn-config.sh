#!/usr/bin/env bash

# Скрипт для генерации клиентского сертификата OpenVPN с помощью easyrsa

set -e  # Прерывать выполнение при ошибке

# ---------- НАСТРОЙКИ ----------
# Директория с openvpn
OPENVPN_DIR="/etc/openvpn"

# Директория с easyrsa (должна быть инициализирована и содержать pki)
EASYRSA_DIR="${OPENVPN_DIR}/server/easy-rsa"

# Директория, из которой Nginx раздаёт файлы (для скачивания .ovpn)
STATIC_DIR="REPLACE_ME"
OUTPUT_DIR="/var/www/html/${STATIC_DIR}"

# Параметры подключения к серверу OpenVPN
SERVER_IP=$(wget -O - -q ifconfig.me/ip)

# Файл базовой конфигурации клиента
BASE_CLIENT="${OPENVPN_DIR}/server/base_client.conf"

# Файл сертификата CA
CA_CERT="${OPENVPN_DIR}/server/ca.crt"

# Файл tls crypt static key
TC_KEY="${OPENVPN_DIR}/server/tc.key"

# ---------- ПРОВЕРКИ ----------
if [ $# -ne 1 ]; then
  echo "Использование: $0 <имя_клиента>"
  exit 1
fi

CLIENT_NAME="$1"

if [ ! -d "${EASYRSA_DIR}" ]; then
  echo "Ошибка: директория easyrsa '${EASYRSA_DIR}' не найдена"
  exit 1
fi

if [ ! -f "${EASYRSA_DIR}/easyrsa" ]; then
  echo "Ошибка: в '${EASYRSA_DIR}' не найден исполняемый файл easyrsa"
  exit 1
fi

if [ ! -d "${OUTPUT_DIR}" ]; then
  echo "Предупреждение: выходная директория '${OUTPUT_DIR}' не существует"
  exit 1;
fi

# ---------- ГЕНЕРАЦИЯ СЕРТИФИКАТА ----------
cd "$EASYRSA_DIR"

CLIENT_CRT="${EASYRSA_DIR}/pki/issued/${CLIENT_NAME}.crt"
CLIENT_KEY="${EASYRSA_DIR}/pki/private/${CLIENT_NAME}.key"
CLIENT_REQ="${EASYRSA_DIR}/pki/reqs/${CLIENT_NAME}.req"
OVPN_FILE="${OUTPUT_DIR}/${CLIENT_NAME}.ovpn"

if [ -f "${CLIENT_CRT}" ] || [ -f "${CLIENT_KEY}" ] || [ -f "${CLIENT_REQ}" ] || [ -f "${OVPN_FILE}" ]; then
  echo "Сгенерированные файлы клиента уже существуют"
  read -r -p "Удалить? [Y/n]: " response

  response=${response,,}

  # Если пользователь ввёл символы y, Y или просто нажал Enter, то удаляем файлы
  if [[ $response =~ ^(y| ) ]] || [[ -z $response ]]; then
    rm -f "${CLIENT_CRT}"
    rm -f "${CLIENT_KEY}"
    rm -f "${CLIENT_REQ}"
    rm -f "${OVPN_FILE}"
  else
    exit 0
  fi
fi

echo "Генерация сертификата для клиента '${CLIENT_NAME}'"

./easyrsa build-client-full "${CLIENT_NAME}" nopass

# Проверка, что файлы создались
if [ ! -f "${CLIENT_CRT}" ] || [ ! -f "${CLIENT_KEY}" ]; then
  echo "Ошибка: не удалось найти сгенерированные файлы клиента"
  exit 1
fi

# ---------- СБОРКА OVPN ФАЙЛА ----------
echo "Создание файла конфигурации ${OVPN_FILE}"

# Начало файла .ovpn
cat > "${OVPN_FILE}" <<EOF
$(cat "${BASE_CLIENT}")
<ca>
$(cat "${CA_CERT}")
</ca>
<cert>
$(cat "${CLIENT_CRT}")
</cert>
<key>
$(cat "${CLIENT_KEY}")
</key>
<tls-crypt>
$(cat "${TC_KEY}")
</tls-crypt>
EOF

# Устанавливаем права на чтение
chmod 644 "${OVPN_FILE}"

echo "Готово! Файл конфигурации создан: ${OVPN_FILE}"

# Извлекаем относительный путь от корня веб-сервера
REL_PATH="${OUTPUT_DIR#/var/www/html/}"
URL="http://$SERVER_IP/${REL_PATH}/${CLIENT_NAME}.ovpn"
echo "Скачать файл можно по ссылке: $URL"

exit 0
