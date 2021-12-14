. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/vault-agent.hcl.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  | sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" \
  | sed "s${sep}%%unsealip%%${sep}$UNSEALIP${sep}g" \
  > /usr/local/etc/vault-agent.hcl

echo "Configure vault-agent"
cp -a /usr/local/etc/rc.d/vault \
  /usr/local/etc/rc.d/vault-agent
sed -i '' 's/vault_/vault_agent_/g' \
  /usr/local/etc/rc.d/vault-agent
sed -i '' 's/vault.pid/vault-agent.pid/g' \
  /usr/local/etc/rc.d/vault-agent
sed -i '' 's/server/agent/g' \
  /usr/local/etc/rc.d/vault-agent
sed -i '' 's/vault$/vault_agent/g' \
  /usr/local/etc/rc.d/vault-agent

service vault-agent enable
sysrc vault_agent_user=nomad
sysrc vault_agent_group=nomad
sysrc vault_agent_login_class=root
sysrc vault_agent_syslog_output_enable="YES"
sysrc vault_agent_syslog_output_priority="warn"
sysrc vault_agent_config=/usr/local/etc/vault-agent.hcl
