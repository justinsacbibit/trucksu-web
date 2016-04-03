#!/usr/bin/env bash

echo "=== Begin Vagrant Provisioning using 'config/vagrant/shell_setup.sh'"

echo "===== Configuring shell"
echo "cd /vagrant; sudo service nginx start" >> /home/vagrant/.bashrc

echo "=== End Vagrant Provisioning using 'config/vagrant/shell_setup.sh'"
