#!/bin/bash

set -e

MYSQL_PASSWORD=$1
PROJECT_DIR="/var/www/html"

mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
git config --global --ad safe.directory $PROJECT_DIR

if [ ! -d $PROJECT_DIR"/.git" ] ; then
    GIT_SSH_COMMAND='ssh -i /home/vagrant/.ssh/id_rsa -o IdentitiesOnly=yes' git \
    clone git@github.com:santiagopereyramarchetti/laravel-devops.git
else
    GIT_SSH_COMMAND='ssh -i /home/vagrant/.ssh/id_rsa -o IdentitiesOnly=yes' git pull
fi

cd $PROJECT_DIR"/frontend"
npm install
npm run build

cd $PROJECT_DIR"/api"
composer install --no-interaction --optimize-autoloader --no-dev
if [ ! -f $PROJECT_DIR"/api/.env" ] ; then
    cp .env.example .env
    sed -i "/DB_PASSWORD/c\DB_PASSWORD=$MYSQL_PASSWORD" $PROJECT_DIR"/api/.env"
    sed -i "/QUEUE_CONNECTION/C\QUEUE_CONNECTION=database" $PROJECT_DIR"/api/.env"
    php artisan:key generate
fi

chown -R www-data:www-data $PROJECT_DIR

php aritsan storage:link
php artisan optimize:clear

php artisan down

php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

php artisan up

sudo cp $PROJECT_DIR"/deployment/config/nginx.conf" /etc/nginx/nginx.conf

sudo nginx -t
sudo systemctl reload nginx