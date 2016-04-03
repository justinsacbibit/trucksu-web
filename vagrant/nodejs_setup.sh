#!/usr/bin/env bash

echo "=== Begin Vagrant Provisioning using 'config/vagrant/nodejs_setup.sh'"

if [ -z `which nodejs` ]; then
  curl -sL https://deb.nodesource.com/setup_5.x | sudo bash -
  apt-get install -y nodejs
  apt-get install -y build-essential
fi

echo "=== End Vagrant Provisioning using 'config/vagrant/nodejs_setup.sh'"
