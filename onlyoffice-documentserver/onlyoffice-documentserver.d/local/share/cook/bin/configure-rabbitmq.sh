#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in custom config file to set ENV variables.
< "$TEMPLATEPATH/rabbitmq-env.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/rabbitmq/rabbitmq-env.conf

# enable the service
service rabbitmq enable

# start the service
service rabbitmq start || true

# Create a new rabbitmq user for the ONLYOFFICE Document Server configuration
# the documentation for the onlyoffice-documentserver port fails to mention including '--node "name"' to make this work
GETCOOKIE=$(cat /var/db/rabbitmq/.erlang.cookie)
GETNODENAME="rabbit@$_POT_NAME"
/usr/local/sbin/rabbitmqctl --node "$GETNODENAME" --erlang-cookie "$GETCOOKIE" add_user onlyoffice "$SETRABBITONLYOFFICEPASS"
/usr/local/sbin/rabbitmqctl --node "$GETNODENAME" --erlang-cookie "$GETCOOKIE" set_user_tags onlyoffice administrator
/usr/local/sbin/rabbitmqctl --node "$GETNODENAME" --erlang-cookie "$GETCOOKIE" set_permissions -p / onlyoffice ".*" ".*" ".*"

