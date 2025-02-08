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

# make dirs
mkdir -p /mnt/matrixdata/matrix-synapse
mkdir -p /mnt/matrixdata/media_store
mkdir -p /mnt/matrixdata/control
mkdir -p /usr/local/www/well-known/matrix

# double check permissions on directories
chown synapse /mnt/matrixdata
chown -R synapse /mnt/matrixdata/matrix-synapse
chmod -R ugo+rw /mnt/matrixdata/matrix-synapse
chown -R synapse /mnt/matrixdata/media_store
chmod -R ugo+rw /mnt/matrixdata/media_store
chown -R synapse /var/log/matrix-synapse
chown -R synapse /var/run/matrix-synapse

# split domain into parts for use in matrix-synapse ldap configuration
MYSUFFIX=$(echo "${LDAPDOMAIN}" | awk -F '.' 'NF>=2 {print $(NF-1)}')
MYTLD=$(echo "${LDAPDOMAIN}" | awk -F '.' 'NF>=2 {print $(NF)}')
echo "From domain name of ${LDAPDOMAIN} we get MYSUFFIX of ${MYSUFFIX} and MYTLD of ${MYTLD}"

# generate macaroon and form key
MYMACAROON=$(/usr/bin/openssl rand -base64 48)
MYFORMKEY=$(/usr/bin/openssl rand -base64 48)

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy over log config
cp -f "$TEMPLATEPATH/my.log.config.in" /usr/local/etc/matrix-synapse/my.log.config

# generate basic setup
/usr/local/bin/python3.9 -B -m synapse.app.homeserver -c /usr/local/etc/matrix-synapse/homeserver.yaml --generate-config -H "${DOMAIN}" --report-stats no
mv /usr/local/etc/matrix-synapse/homeserver.yaml /usr/local/etc/matrix-synapse/homeserver.yaml.generated

# set variables and copy over homeserver.yaml
< "$TEMPLATEPATH/homeserver.yaml.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%alertemail%%${sep}$ALERTEMAIL${sep}g" | \
  sed "s${sep}%%registrationenable%%${sep}$REGISTRATIONENABLE${sep}g" | \
  sed "s${sep}%%mysharedsecret%%${sep}$MYSHAREDSECRET${sep}g" | \
  sed "s${sep}%%mymacaroon%%${sep}$MYMACAROON${sep}g" | \
  sed "s${sep}%%myformkey%%${sep}$MYFORMKEY${sep}g" | \
  sed "s${sep}%%smtphost%%${sep}$SMTPHOST${sep}g" | \
  sed "s${sep}%%smtpport%%${sep}$SMTPPORT${sep}g" | \
  sed "s${sep}%%smtpuser%%${sep}$SMTPUSER${sep}g" | \
  sed "s${sep}%%smtppass%%${sep}$SMTPPASS${sep}g" | \
  sed "s${sep}%%ldapserver%%${sep}$LDAPSERVER${sep}g" | \
  sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
  sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
  sed "s${sep}%%ldappassword%%${sep}$LDAPPASSWORD${sep}g" \
  > /usr/local/etc/matrix-synapse/homeserver.yaml

# set synapse as owner for DOMAIN.signing.key
chown synapse:wheel "/usr/local/etc/matrix-synapse/$DOMAIN.signing.key"

# enable matrix
service synapse enable || true
