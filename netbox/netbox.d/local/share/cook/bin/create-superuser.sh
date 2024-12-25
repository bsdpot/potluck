#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH=/usr/local/bin:$PATH

# Success on first create:
#  Superuser created successfully.
# Failure on repeat:
#  CommandError: Error: That username is already taken.
#
cd /usr/local/share/netbox || exit 1
if ! /usr/local/bin/python3.11 manage.py check >/dev/null 2>&1; then
	DJANGO_SUPERUSER_PASSWORD="$ADMINPASSWORD" /usr/local/bin/python3.11 manage.py createsuperuser --no-input --username "$ADMINNAME" --email "$ADMINEMAIL" || true
fi
