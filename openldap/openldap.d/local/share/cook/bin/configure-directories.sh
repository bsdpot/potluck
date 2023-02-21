#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# The database directory MUST exist prior to running slapd AND
# should only be accessible by the slapd and slap tools.
# Mode 700 recommended.

# make database directory if doesn't exist, plus backups directory
mkdir -p /mnt/openldap-data/backups

# double check permissions on directories
chown -R ldap:ldap /mnt/openldap-data
chmod 700 /mnt/openldap-data
chown -R ldap:ldap /usr/local/etc/openldap/slapd.d
