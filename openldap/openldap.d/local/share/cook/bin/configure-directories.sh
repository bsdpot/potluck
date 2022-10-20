#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# check that /mnt/openldap-data exists
if [ ! -d /mnt/openldap-data ]; then
    echo "ERROR: /mnt/openldap-data does not exist. Where is the persistent storage mount-in?"
    exit 1
fi

# double check permissions on directories
chown -R ldap:ldap /mnt/openldap-data
chmod 700 /mnt/openldap-data
chown -R ldap:ldap /usr/local/etc/openldap/slapd.d
