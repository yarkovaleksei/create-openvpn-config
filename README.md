# create-openvpn-config

**Bash скрипт, генерирующий готовый к использованию ovpn файл**

После инициализации сервера [TimeWeb с образом OpenVPN](https://timeweb.cloud/my/servers/create?zone=ams-1&os=79&software=129&configurator=21&cpu=2&gpu=0&ram=2&drive=40) в панели управления доступны 3 конфига ovpn. Частенько этого маловато и хочется каждому клиенту сгенерировать его личный конфиг.

Для этого надо выполнить следующие шаги:
```bash
# Скачать скрипт
wget -O create-openvpn-config.sh https://raw.githubusercontent.com/yarkovaleksei/create-openvpn-config/refs/heads/master/create-openvpn-config.sh
# Сделать его исполняемым
chmod +x ./create-openvpn-config.sh
# Теперь в каталоге /var/www/html/ надо посмотреть имя папки с файлами ovpn
root@openvpn-server:~# ls -al /var/www/html/
total 16
drwxr-xr-x 3 root root 4096 Mar  9  2025 .
drwxr-xr-x 3 root root 4096 Mar  9  2025 ..
drwxr-xr-x 2 root root 4096 Mar  8 11:42 1f9263ef-f6ad-4aa7-aed3-4b3e920e890e
-rw-r--r-- 1 root root  612 Mar  9  2025 index.nginx-debian.html
# Исправляем соответствующую строку в скрипте
sed -i.bak '/STATIC_DIR="REPLACE_ME"/c\STATIC_DIR="1f9263ef-f6ad-4aa7-aed3-4b3e920e890e"' ./create-openvpn-config.sh
# И можно запускать файл
./create-openvpn-config.sh client-name
```

Если запустить скрипт повторно с этим же client name и будут найдены существующие файлы, то будет предложено их удалить. Для удаления надо ввести y, Y или просто нажать Enter. В противном случае скрипт завершит работу.
