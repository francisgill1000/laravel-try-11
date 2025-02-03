#!/bin/bash

# Define variables
SERVER_IP="159.223.172.67"
PORT="8000"

# Update and install necessary packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common curl unzip sqlite3 git nginx

# Add PHP repository and install PHP 8.2 with required extensions
sudo add-apt-repository ppa:ondrej/php -y
sudo apt install -y php php-fpm php-cli php-mbstring php-xml php-bcmath php-json php-zip php-curl sqlite3 libsqlite3-dev unzip curl php-sqlite3 

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Clone Laravel project
cd /var/www && sudo git clone https://github.com/francisgill1000/laravel-try-11
cd laravel-try-11

# Install Laravel dependencies
sudo composer install

# Configure environment file
sudo cp .env.example .env
sudo php artisan key:generate

# Run migrations
sudo php artisan migrate

# Configure Nginx for Laravel with dynamic IP and PORT
NGINX_CONF="/etc/nginx/sites-available/laravel-try-11"
sudo cat > "$NGINX_CONF" <<EOF
server {
    listen $PORT;
    server_name $SERVER_IP;
    root /var/www/laravel-try-11/public;

    index index.php index.html index.htm;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    error_log /var/log/nginx/laravel-error.log;
    access_log /var/log/nginx/laravel-access.log;
}
EOF

# Enable the site and restart Nginx
sudo ln -s /etc/nginx/sites-available/laravel-try-11 /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Ensure proper permissions again
sudo chown -R www-data:www-data /var/www/laravel-try-11
sudo chmod -R 775 /var/www/laravel-try-11

echo "Laravel setup completed successfully! Access it at http://$SERVER_IP:$PORT"
