#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Помилка: Цей скрипт потрібно запускати через sudo"
  exit 1
fi

echo "Оновлення системи та встановлення пакетів"
apt-get update
apt-get install -y nginx mariadb-server nodejs npm git sudo curl

echo "Створення користувачів системи"
if ! id "student" &>/dev/null; then
    useradd -m -s /bin/bash student
    echo "student:12345678" | chpasswd
    usermod -aG sudo student
    chage -d 0 student
fi

if ! id "teacher" &>/dev/null; then
    useradd -m -s /bin/bash teacher
    echo "teacher:12345678" | chpasswd
    usermod -aG sudo teacher
    chage -d 0 teacher
fi

if ! id "operator" &>/dev/null; then
    useradd -m -s /bin/bash -g operator operator
    echo "operator:12345678" | chpasswd
    chage -d 0 operator
fi

if ! id "app" &>/dev/null; then
    useradd -r -s /bin/false app
fi

echo "Створення файлу gradebook"
echo "8" > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 644 /home/student/gradebook

echo "Налаштування бази даних MariaDB"
systemctl start mariadb
systemctl enable mariadb

mysql -e "CREATE DATABASE IF NOT EXISTS inventory CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'app_user'@'localhost' IDENTIFIED BY 'app_password';"
mysql -e "GRANT ALL PRIVILEGES ON inventory.* TO 'app_user'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "Завантаження коду з GitHub"
APP_DIR="/opt/mywebapp"

rm -rf $APP_DIR
rm -rf /tmp/trpz-labs

git clone https://github.com/yusik100/2-course-trpz.git /tmp/trpz-labs

cp -r /tmp/trpz-labs/lab1/mywebapp $APP_DIR

rm -rf /tmp/trpz-labs

cd $APP_DIR
npm install

chown -R app:app $APP_DIR

echo "Налаштування Systemd Socket Activation"

cat << 'EOF' > /etc/systemd/system/mywebapp.socket
[Unit]
Description=My Web App Socket

[Socket]
ListenStream=127.0.0.1:8000

[Install]
WantedBy=sockets.target
EOF

cat << 'EOF' > /etc/systemd/system/mywebapp.service
[Unit]
Description=My Web App (Simple Inventory)
Requires=mywebapp.socket
After=network.target mariadb.service mywebapp.socket

[Service]
Type=simple
User=app
WorkingDirectory=/opt/mywebapp
ExecStartPre=/usr/bin/node /opt/mywebapp/migrate.js --dbuser=app_user --dbpass=app_password --dbname=inventory
ExecStart=/usr/bin/node /opt/mywebapp/mywebapp.js --port=8000 --dbuser=app_user --dbpass=app_password --dbname=inventory
Restart=on-failure
EOF

systemctl daemon-reload
systemctl enable mywebapp.socket
systemctl start mywebapp.socket

echo "Налаштування Nginx"
cat << 'EOF' > /etc/nginx/sites-available/mywebapp
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/mywebapp_access.log;

    location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
    }
    
    location /items {
        proxy_pass http://127.0.0.1:8000/items;
        proxy_set_header Host $host;
    }

    location /health {
        deny all;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
systemctl restart nginx

echo "Налаштування прав користувача operator"
cat << 'EOF' > /etc/sudoers.d/operator
operator ALL=(ALL) NOPASSWD: /bin/systemctl start mywebapp, /bin/systemctl stop mywebapp, /bin/systemctl restart mywebapp, /bin/systemctl status mywebapp, /bin/systemctl reload nginx
EOF
chmod 440 /etc/sudoers.d/operator

echo "Блокування дефолтного користувача"
DEFAULT_USER=$(id -un 1000 2>/dev/null || true)
if [ -n "$DEFAULT_USER" ] && [ "$DEFAULT_USER" != "student" ]; then
    usermod -L $DEFAULT_USER
    echo "Дефолтного користувача $DEFAULT_USER успішно заблоковано."
fi

echo "Встановлення та налаштування завершено"