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

# create index via fake elasticsearch
# this should address the error:
# 'core.MultiSearchV2: error accessing reader: no index found'
# Any index will do, just needs to be an existing index before parsedmarc will import correctly
#
# check zincsearch responding
zinclivecheck=$(/usr/local/bin/curl -s "http://localhost:9200/" | jq -r .name )
if [ "$zinclivecheck" = "zinc" ]; then
	# create default index
	echo "Creating a default zincsearch index"
	/usr/local/bin/curl --user "$ZINCUSER:$ZINCPASS" -X PUT -d '{}' http://localhost:9200/sampleindex || true
else
	echo "cannot create index, zincsearch is not live"
	exit 1
fi

# create virtualenv
sudo -u parsedmarc virtualenv /opt/parsedmarc/venv || true

# activate virtualenv
. /opt/parsedmarc/venv/bin/activate || true

# install parsedmarc
sudo -u parsedmarc /opt/parsedmarc/venv/bin/pip install -U parsedmarc || true

# deactivate the virtual environment
deactivate

# make sure the process can write to log file
touch /var/log/python-parsedmarc.log
chown parsedmarc /var/log/python-parsedmarc.log

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
  sed "s${sep}%%outputfolder%%${sep}$OUTPUTFOLDER${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%zincuser%%${sep}$ZINCUSER${sep}g" | \
  sed "s${sep}%%zincpass%%${sep}$ZINCPASS${sep}g" \
  > /usr/local/etc/parsedmarc.ini

# set the ownership of the config file. This could be changed
# to something only root can read but parsedmarc service can read too?
chown parsedmarc /usr/local/etc/parsedmarc.ini

# as user parsedmarc run
#   /opt/parsedmarc/venv/bin/parsedmarc -c /usr/local/etc/parsedmarc.ini
# this takes a long time to complete so should not be a pot startup command
# rather a service that starts some other way and backgrounds after the pot
# image is live

# copy over the rc script
cp -f "$TEMPLATEPATH/parsedmarc.rc.in" /usr/local/etc/rc.d/parsedmarc

# set executable bit on rc file
chmod +x /usr/local/etc/rc.d/parsedmarc

# enable the service
service parsedmarc enable || true

# start the service so long
service parsedmarc start || true
