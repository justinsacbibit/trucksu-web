#!/usr/bin/env bash

echo "=== Begin Vagrant Provisioning using 'config/vagrant/nginx_setup.sh'"

echo "===== Installing nginx"
apt-get -y install nginx
service nginx start

ln -sf /vagrant/vagrant/nginx/nginx.conf /etc/nginx/sites-available/site.conf
chmod 644 /etc/nginx/sites-available/site.conf
ln -sf /etc/nginx/sites-available/site.conf /etc/nginx/sites-enabled/site.conf
service nginx restart

echo "=== End Vagrant Provisioning using 'config/vagrant/nginx_setup.sh'"
