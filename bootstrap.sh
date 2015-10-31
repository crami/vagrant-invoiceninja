#!/usr/bin/env bash

sed -i -e 's/mirror.rit.edu/mirror.iway.ch/' /etc/apt/sources.list

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y
apt-get install -y python-software-properties git curl openssl pwgen joe
apt-get install -y nginx php5-fpm php5-cli php5-mcrypt php5-gd php5-curl

ROOT_MYSQL_PASS=$(pwgen -s 12 1);

debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password password $ROOT_MYSQL_PASS"
debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password_again password $ROOT_MYSQL_PASS"

apt-get install -y --allow-unauthenticated mariadb-server mariadb-client php5-mysql

if [ -f /vagrant/.mysql-passes ]
  then
      rm -f /vagrant/.mysql-passes
  fi
echo "root:${ROOT_MYSQL_PASS}" >> /vagrant/.mysql-passes

MYSQLPW=$(pwgen 12 1)

echo "Initializing Database"

echo "ininjauser password: '${MYSQLPW}'"

echo "CREATE DATABASE ininja;
GRANT ALL PRIVILEGES ON ininja.* TO 'ininjauser'@'localhost' IDENTIFIED BY '${MYSQLPW}';
FLUSH PRIVILEGES;
\q
" | mysql --defaults-file=/etc/mysql/debian.cnf

echo "ininjauser:${MYSQLPW}" >> /vagrant/.mysql-passes

echo "Installing Composer"

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

composer config --global github-oauth.github.com 641381d0cd6316c07971f49fc34fcc9b3e171a76

rm -rf /var/www

echo "Cloning invoice ninja"

git clone https://github.com/hillelcoren/invoice-ninja.git /var/www
cd /var/www

composer install --no-dev -o

if ! [ -f /var/www/.env ]; then

  KEY=$(php artisan key:generate --show --no-ansi)

  cat >/var/www/.env<<EOM
APP_ENV=production
APP_DEBUG=false
# APP_URL=https://ninja.dev
APP_CIPHER=rijndael-128
APP_KEY=${KEY}
APP_TIMEZONE=Europe/Zurich

DB_TYPE=mysql
DB_HOST=localhost
DB_DATABASE=ininja
DB_USERNAME=ininjauser
DB_PASSWORD=${MYSQLPW}

MAIL_DRIVER=smtp
MAIL_PORT=587
MAIL_ENCRYPTION=tls
MAIL_HOST
MAIL_USERNAME
MAIL_FROM_ADDRESS
MAIL_FROM_NAME
MAIL_PASSWORD

#PHANTOMJS_CLOUD_KEY='a-demo-key-with-low-quota-per-ip-address'

LOG=single
EOM

  php artisan migrate --force
  php artisan db:seed --force
fi

rm /etc/nginx/sites-enabled/default
ln -s /vagrant/nginx-default /etc/nginx/sites-enabled/default

if ! [ -f /vagrant/ininja.crt ]; then
  openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=CH/ST=Zurich/L=Zurich/O=IN/CN=invoiceninja.example.com" \
    -keyout /vagrant/ininja.key  -out /vagrant/ininja.crt
fi

chown -R www-data:www-data /var/www

service nginx restart

