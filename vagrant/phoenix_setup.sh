#!/usr/bin/env bash

echo "=== Begin Vagrant Provisioning using 'config/vagrant/phoenix_setup.sh'"

PHOENIX_VERSION=1.1.4

echo "===== Installing Phoenix"
yes Y | mix local.hex
yes Y | mix archive.install "https://github.com/phoenixframework/archives/raw/master/phoenix_new-$PHOENIX_VERSION.ez"

echo "=== End Vagrant Provisioning using 'config/vagrant/phoenix_setup.sh'"
