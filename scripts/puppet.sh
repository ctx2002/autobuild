#!/bin/bash -eux
#install puppet agent

wget https://apt.puppetlabs.com/puppet-release-bionic.deb
dpkg -i puppet-release-bionic.deb
apt-get update
apt-get -y install puppet