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

cd /usr/local/share/netbox || exit 1
if ! /usr/local/bin/python3.11 manage.py check >/dev/null 2>&1; then
	/usr/local/bin/python3.11 manage.py migrate
	/usr/local/bin/python3.11 manage.py trace_paths --no-input
	/usr/local/bin/mkdocs build
	/usr/local/bin/python3.11 manage.py collectstatic --no-input
	/usr/local/bin/python3.11 manage.py remove_stale_contenttypes --no-input
	/usr/local/bin/python3.11 manage.py reindex --lazy
	/usr/local/bin/python3.11 manage.py clearsessions
fi
