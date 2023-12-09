#!/bin/bash

set -x

echo "[TASK 01] install postgresql"
echo "----------------------------------------"
sudo dnf install -y epel-release
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install postgresql15-server postgresql15-contrib patroni python3-pip python3-consul python3-pip watchdog \
  --nodocs --setopt install_weak_deps=false --best -y

# suport only
sudo dnf install net-tools --nodocs --setopt install_weak_deps=false --best -y

echo "[TASK 02] make consul directory"
echo "----------------------------------------"
sudo mkdir -p /etc/consul/config /etc/consul/data /var/log/consul

echo "make consul configuration file"
sudo cat > /etc/consul/config/config.hcl << DATA
server    = false
advertise_addr = "{{ GetInterfaceIP \"eth1\" }}"
bind_addr = "0.0.0.0"
data_dir  = "/etc/consul/data"
log_file  = "/var/log/consul/consul.log"
log_rotate_max_files = 10
log_level = "debug"
ui_config {
  enabled = false
}
addresses {
  http = "0.0.0.0"
}

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

echo "[TASK 03]"
echo "----------------------------------------"
sudo mkdir -p /etc/patroni /data/postgresql
sudo chown -R postgres:postgres /data/postgresql
sudo pip3 install patroni[consul]

echo "make patroni config"
sudo cat > /etc/patroni/config.yaml << DATA 
name: "$(hostname)"
scope: db-gitlab
namespace: /database/
consul:
  url: http://127.0.0.1:8500
  register_service: true
postgresql:
  connect_address: "$(hostname):5432"
  bin_dir: /usr/pgsql-15/bin/
  data_dir: /data/postgresql/15/data
  listen: "*:5432"
  authentication:
    replication:
      username: replicator
      sslmode: disable
  pg_hba:
    "local" is for Unix domain socket connections only
    - local   all         all                         peer

    # IPv4 local connections:
    - host    all         all         127.0.0.1/32    scram-sha-256
    - host    all         all         0.0.0.0/0       scram-sha-256

    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    - host    replication replicator  10.0.0.21/32    trust
    - host    replication replicator  10.0.0.22/32    trust
    # - host    replication replicator  10.0.0.23/32  trust
restapi:
  connect_address: "$(hostname):8008"
  listen: "*:8008"
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      parameters:
        max_connections: 500

  initdb:
    - encoding: UTF8
DATA

echo "make patroni service"
sudo cat > /etc/systemd/system/patroni.service << DATA
[Unit]
Description="A template for PostgreSQL High Availability with Etcd, Consul, ZooKeeper, or Kubernetes"
Requires=network-online.target consul.service
After=network-online.target consul.service

[Service]
User=postgres
Group=postgres
Environment=HOME="/var/lib/pgsql"
WorkingDirectory=/var/lib/pgsql
ExecStart=/bin/patroni /etc/patroni/config.yaml
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
TimeoutSec=30
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
DATA

echo "enable patroni service"
sudo systemctl enable --now patroni