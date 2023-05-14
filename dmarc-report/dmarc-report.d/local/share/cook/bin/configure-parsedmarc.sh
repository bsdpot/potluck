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
  /usr/sbin/pw useradd -n parsedmarc -c 'parsedmarc user' -m -d /opt/parsedmarc -s /bin/sh -h -
fi

# create a folder for output reports in json and csv
mkdir -p "/mnt/$OUTPUTFOLDER"
chown -R parsedmarc "/mnt/$OUTPUTFOLDER"

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

# copy in custom parsedmarc.ini file
< "$TEMPLATEPATH/parsedmarc.ini.in" \
  sed "s${sep}%%imapserver%%${sep}$IMAPSERVER${sep}g" | \
  sed "s${sep}%%imapuser%%${sep}$IMAPUSER${sep}g" | \
  sed "s${sep}%%imappass%%${sep}$IMAPPASS${sep}g" | \
  sed "s${sep}%%imapfolder%%${sep}$IMAPFOLDER${sep}g" | \
  sed "s${sep}%%outputfolder%%${sep}$OUTPUTFOLDER${sep}g" \
  > /usr/local/etc/parsedmarc.ini

# need steps to run python process to get report
#
# as user parsedmarc run
# /opt/parsedmarc/venv/bin/parsedmarc -c /usr/local/etc/parsedmarc.ini
#
# this takes a long time to complete so should not be a pot startup command
# rather a service that starts some other way and backgrounds after the pot
# image is live

