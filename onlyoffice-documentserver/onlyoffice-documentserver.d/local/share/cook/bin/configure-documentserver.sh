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

# this may need some work, enable during development testing
mkdir -p /mnt/private
echo "Use the following secret string for the document server:" > /mnt/private/documentserver.txt
echo "$SETSECRETSTRING" >> /mnt/private/documentserver.txt

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in custom local.json
< "$TEMPLATEPATH/local.json.in" \
  sed "s${sep}%%dbhost%%${sep}$DBHOST${sep}g" | \
  sed "s${sep}%%dbport%%${sep}$SETDBPORT${sep}g" | \
  sed "s${sep}%%dbname%%${sep}$DBNAME${sep}g" | \
  sed "s${sep}%%dbuser%%${sep}$DBUSER${sep}g" | \
  sed "s${sep}%%dbpass%%${sep}$DBPASS${sep}g" | \
  sed "s${sep}%%verysecretstring%%${sep}$SETSECRETSTRING${sep}g" | \
  sed "s${sep}%%rabbitonlyofficepass%%${sep}$SETRABBITONLYOFFICEPASS${sep}g" | \
  sed "s${sep}%%rabbitnodename%%${sep}$_POT_NAME${sep}g" \
  > /usr/local/etc/onlyoffice/documentserver/local.json

# unset these for plugin install
set +e
# shellcheck disable=SC3040
set +o pipefail

# install plugins, requires internet access
/usr/local/bin/documentserver-pluginsmanager.sh --update=/usr/local/www/onlyoffice/documentserver/sdkjs-plugins/plugin-list-default.json

# set back after plugin install
set -e
# shellcheck disable=SC3040
set -o pipefail