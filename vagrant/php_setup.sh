#!/usr/bin/env bash

echo "=== Begin Vagrant Provisioning using 'config/vagrant/php_setup.sh'"

echo "===== Installing php"
apt-get -y install php5-cli
apt-get -y install php5-mcrypt
echo "extension=mcrypt.so" >> /etc/php5/cli/php.ini

echo "=== End Vagrant Provisioning using 'config/vagrant/php_setup.sh'"
