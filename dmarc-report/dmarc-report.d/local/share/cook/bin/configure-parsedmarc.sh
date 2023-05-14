#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# add parsedmarc user
if ! id -u "parsedmarc" >/dev/null 2>&1; then
  /usr/sbin/pw useradd -n parsedmac -c 'parsedmarc user' -m -d /opt/parsedmarc -s /bin/sh -h -
fi

# create virtualenv
sudo -u parsedmarc virtualenv /opt/parsedmarc/venv || true

# activate virtualenv
. /opt/parsedmarc/venv/bin/activate || true

# install parsedmarc
sudo -u parsedmarc /opt/parsedmarc/venv/bin/pip install -U parsedmarc || true

# deactivate the virtual environment
deactivate

# Adapt config files
SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

## copy in custom .env file
#< "$TEMPLATEPATH/env.in" \
#  sed "s${sep}%%imapserver%%${sep}$IMAPSERVER${sep}g" | \
#  sed "s${sep}%%imapuser%%${sep}$IMAPUSER${sep}g" | \
#  sed "s${sep}%%imappass%%${sep}$IMAPPASS${sep}g" | \
#  sed "s${sep}%%imapfolder%%${sep}$IMAPFOLDER${sep}g" | \
#  sed "s${sep}%%serverport%%${sep}$SERVERPORT${sep}g" \
#  > /root/dmarc-report/.env

