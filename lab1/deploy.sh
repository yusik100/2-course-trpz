#!/bin/bash
set -e

IMAGE_NAME=$1

echo "Починаємо розгортання образу: $IMAGE_NAME"

sudo apt-get update
sudo apt-get install -y docker.io nginx curl

cat <<EOF | sudo tee /etc/systemd/system/mywebapp.service
[Unit]
Description=My Web App Docker Container
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker rm -f mywebapp-container
ExecStart=/usr/bin/docker run --name mywebapp-container -p 3000:8000 $IMAGE_NAME
ExecStop=/usr/bin/docker stop mywebapp-container

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mywebapp.service
sudo systemctl restart mywebapp.service

cat <<EOF | sudo tee /etc/nginx/sites-available/mywebapp
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "Розгортання успішно завершено"