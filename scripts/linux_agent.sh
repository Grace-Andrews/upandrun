#!/bin/bash
set -ex
hostname linux.vm
echo '192.168.50.4 master.vm master' >> /etc/hosts
echo '192.168.50.6 linux.vm linux' >> /etc/hosts
curl -k https://master.vm:8140/packages/current/install.bash | bash
