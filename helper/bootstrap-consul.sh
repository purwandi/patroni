#!/bin/bash

set -x

echo "make consul directory"
sudo mkdir -p /etc/consul/config /etc/consul/data /var/log/consul

echo "make consul configuration file"
sudo cat > /etc/consul/config/config.hcl << DATA
server    = true
advertise_addr = "{{ GetInterfaceIP \"eth1\" }}"
bind_addr = "0.0.0.0"
data_dir  = "/etc/consul/data"
log_file  = "/var/log/consul/consul.log"
log_rotate_max_files = 10
log_level = "debug"
ui_config {
  enabled = true
}
addresses {
  http = "0.0.0.0"
}
bootstrap_expect = 3
retry_join = [ "consul-01", "consul-02", "consul-03" ]
encrypt = "owrZdQmyZqrixNW7tvrfgwvLeYFA3wSJXV9Ds49mc8Y="
disable_update_check = true
DATA

echo "make consul service"
sudo cat > /etc/systemd/system/consul.service << DATA
[Unit]
Description="Hashicorp Consul - A service mesh solution"
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/bin/bash -c "/usr/bin/consul agent -node $(hostname) -config-dir /etc/consul/config"
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
DATA

echo "enable consul service and starting it"
sudo systemctl enable --now consul