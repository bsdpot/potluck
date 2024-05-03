#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
  . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:"$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# make sure /usr/local/www/adminer exists
if [ ! -d "/usr/local/www/adminer" ]; then
  echo "/usr/local/www/adminer missing, nginx configuration probably failed."
  exit 1
fi

# Fetch adminer full release unless EDITOR=true in env
if [ -n "$EDITOR" ] && [ "$EDITOR" = true ]; then
  curl -L -o /usr/local/www/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/editor-4.8.1.php
else
  curl -L -o /usr/local/www/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
fi

# Use adminer with a login page unless DBSERVER is set
if [ -n "$DBSERVER" ]; then
  ln -s /usr/local/www/adminer/adminer.php /usr/local/www/adminer/index.php
else
< "$TEMPLATEPATH/index.php.in" \
  sed "s${sep}%%DBSERVER%%${sep}$DBSERVER${sep}g" | \
  sed "s${sep}%%DBUSER%%${sep}$DBUSER${sep}g" | \
  sed "s${sep}%%DBPASS%%${sep}$DBPASS${sep}g" | \
  sed "s${sep}%%DBNAME%%${sep}$DBNAME${sep}g" | \
  sed "s${sep}%%DBDRIVER%%${sep}$DBDRIVER${sep}g" \
    > /usr/local/www/adminer/index.php
fi
