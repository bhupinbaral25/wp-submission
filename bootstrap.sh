#!/usr/bin/  bash

echo "Up Vagrant"
sudo apt update -y

echo "Adding vagrant user to group www-data"
sudo usermod -a -G www-data  vagrant

echo "Installing ngnix  server"
sudo apt install nginx -y

echo "Starting ngnix server in this virtualmachine"
sudo systemctl stop nginx.service
sudo systemctl start nginx.service
sudo systemctl enable nginx.service

echo "Installing the mysql server"
sudo apt install mysql-server -y

echo "Secure Database Setup"

mysql -u root -e "\
	CREATE DATABASE snipeit; \
	CREATE USER 'snipeit'@'localhost' IDENTIFIED BY 'Password@#';\
	GRANT ALL ON snipeit.* TO 'snipeit_user'@'localhost' WITH GRANT OPTION;\
	FLUSH PRIVILEGES;"


echo "Installing php 7.4"
apt install php7.4 libapache2-mod-php7.4 php7.4-common php7.4-gmp php7.4-curl php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-mysql php7.4-gd php7.4-bcmath php7.4-xml php7.4-cli php7.4-zip php7.4-sqlite3 php7.4-ldap -y

sudo apt install curl git
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

echo "getting snipeit in device"
cd /var/www/
rm -rf snipeit
sudo git clone https://github.com/snipe/snipe-it snipeit
sudo cp /var/www/snipeit/.env.example /var/www/snipeit/.env

echo "updating environment"
sudo sed -i "s/DB_DATABASE=null/DB_DATABASE=snipeit/g" /var/www/snipeit/.env
sudo sed -i "s/DB_USERNAME=null/DB_USERNAME=snipeit_user/g" /var/www/snipeit/.env
sudo sed -i "s/DB_PASSWORD=null/DB_PASSWORD=Password@#/g" /var/www/snipeit/.env
sudo sed -i "s/APP_URL=null/APP_URL=snipe-it.local/g" /var/www/snipeit/.env

echo "installing composer"
cd /var/www/snipeit
sudo composer install --no-dev --prefer-source
sudo php artisan key:generate -y

echo "setup permission"
chown -R www-data:www-data /var/www/snipeit/
chmod -R 755 /var/www/snipeit

echo "updating ngnix config"
sudo touch /etc/nginx/sites-available/snipeit
sudo chmod +777 /etc/nginx/sites-available/snipeit
cat /vagrant/ngnixconfig >>/etc/nginx/sites-available/snipeit

echo "setup ngnix conf"
sudo ln -s /etc/nginx/sites-available/snipeit /etc/nginx/sites-enabled/
sudo systemctl restart nginx.service

