#!/bin/bash -eux
add-apt-repository ppa:ondrej/php
apt-get update
apt-get install -y php7.2 php7.2-common php7.2-cli php7.2-fpm
apt-get install php7.2-mysql php7.2-curl php7.2-json php7.2-cgi php7.2-xsl
