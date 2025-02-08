#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH="/usr/local/bin:$PATH"

cd /usr/local/share/netbox || exit 1
# this upgrades the database schema
/usr/local/bin/python3.11 manage.py migrate
/usr/local/bin/python3.11 manage.py trace_paths --no-input
# making docs has error output but success overall
/usr/local/bin/mkdocs build || true
# this generates the files in static/ for the web server
/usr/local/bin/python3.11 manage.py collectstatic --no-input
/usr/local/bin/python3.11 manage.py remove_stale_contenttypes --no-input
/usr/local/bin/python3.11 manage.py reindex --lazy
/usr/local/bin/python3.11 manage.py clearsessions
