#!/bin/bash
# b6-1 user-data: install Nginx with /health endpoint
set -e
apt-get update -y
apt-get install -y nginx

cat > /etc/nginx/sites-available/default << 'NGINXCONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location /health {
        add_header Content-Type text/plain;
        return 200 'OK';
    }

    location / {
        add_header Content-Type text/html;
        return 200 '<html><body><h1>Hello Cloud &mdash; b6-1</h1><p>codyssey-b6-1 | Jack B.</p></body></html>';
    }
}
NGINXCONF

nginx -t
systemctl restart nginx
systemctl enable nginx
