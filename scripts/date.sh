#!/bin/bash -eux

timedatectl set-timezone Pacific/Auckland
apt-get -y install ntp
systemctl restart ntp