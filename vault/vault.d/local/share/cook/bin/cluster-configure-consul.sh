#!/bin/sh

set -e

cp -a /usr/local/etc/rc.d/consul-template \
  /usr/local/etc/rc.d/consul-template-consul
sed -i '' 's/consul_template/consul_template_consul/g' \
  /usr/local/etc/rc.d/consul-template-consul
sed -i '' 's/consul-template/consul-template-consul/g' \
  /usr/local/etc/rc.d/consul-template-consul
ln -s /usr/local/bin/consul-template \
  /usr/local/bin/consul-template-consul

## start consul config
# make consul configuration directory and set permissions
mkdir -p /usr/local/etc/consul.d
chown consul /usr/local/etc/consul.d
chmod 750 /usr/local/etc/consul.d

# set owner and perms on _directory_ /usr/local/etc/consul.d with agent.hcl
chown -R consul:wheel /usr/local/etc/consul.d/

# enable consul
service consul enable

# set load parameter for consul config
sysrc consul_args="-config-file=/usr/local/etc/consul.d/agent.hcl"
sysrc consul_syslog_output_priority="warn"
#sysrc consul_datadir="/var/db/consul"
#sysrc consul_group="wheel"

# setup consul logs, might be redundant if not specified in agent.hcl above
mkdir -p /var/log/consul
touch /var/log/consul/consul.log
chown -R consul:wheel /var/log/consul
