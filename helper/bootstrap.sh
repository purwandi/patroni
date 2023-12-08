#!/bin/bash

set -x

echo "add public key to local machine"
cat /home/vagrant/.ssh/me.pub >> /home/vagrant/.ssh/authorized.keys

echo "move consul binary to system"
sudo mv /home/vagrant/.local/bin/consul /usr/bin/consul
chmod +x /usr/bin/consul

echo "set hostname"
cat >> /etc/hosts << DATA 
10.0.0.2    bastion
10.0.0.11   consul-01
10.0.0.12   consul-02
10.0.0.13   consul-03

10.0.0.21   database-01
10.0.0.22   database-02
10.0.0.23   database-03
DATA