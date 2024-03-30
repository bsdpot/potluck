#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# create log file for debug messages
touch /var/log/slapd.log
chown ldap:ldap /var/log/slapd.log

# create password
SETSLAPPASS=$(/usr/local/sbin/slappasswd -s "$MYCREDS")

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# make sure the outside IP is set to hostname localldap
echo "$IP localldap" >> /etc/hosts

if [ -n "$REMOTEIP" ]; then
	# make sure remoteldap is in /etc/hosts
	echo "$REMOTEIP remoteldap" >> /etc/hosts
	# configure multi server mirror mode ldap
    < "$TEMPLATEPATH/multi-slapd.conf.in" \
    sed "s${sep}%%serverid%%${sep}$SERVERID${sep}g" | \
    sed "s${sep}%%remoteserverid%%${sep}$REMOTESERVERID${sep}g" | \
    sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
    sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
    sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
    sed "s${sep}%%setslappass%%${sep}$SETSLAPPASS${sep}g" | \
    sed "s${sep}%%remoteip%%${sep}$REMOTEIP${sep}g" \
    > /usr/local/etc/openldap/slapd.conf
else
    < "$TEMPLATEPATH/slapd.conf.in" \
    sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
    sed "s${sep}%%setslappass%%${sep}$SETSLAPPASS${sep}g" | \
    sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" \
    > /usr/local/etc/openldap/slapd.conf
fi

# set ldap owner on config file
chown ldap:ldap /usr/local/etc/openldap/slapd.conf

# remove world-read access
chmod o-rwx /usr/local/etc/openldap/slapd.conf

< "$TEMPLATEPATH/slapd.ldif.in" \
 sed "s${sep}%%setslappass%%${sep}$SETSLAPPASS${sep}g" | \
 sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
 sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" \
> /usr/local/etc/openldap/slapd.ldif

# set ldap owner
chown ldap:ldap /usr/local/etc/openldap/slapd.ldif

# remove world-read
chmod o-rwx /usr/local/etc/openldap/slapd.ldif

< "$TEMPLATEPATH/ldap.conf.in" \
 sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
 sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
 sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" \
> /usr/local/etc/openldap/ldap.conf

# set perms
chown ldap:ldap /usr/local/etc/openldap/ldap.conf
chmod 644 /usr/local/etc/openldap/ldap.conf

# remove any old config
rm -r /usr/local/etc/openldap/slapd.d/* || true

# set permissions so that ldap user owns /usr/local/etc/openldap/slapd.d/
# this is critical to making the below work
chown -R ldap:ldap /usr/local/etc/openldap/slapd.d/

# build a basic config from the included slapd.CONF file (capitalised for emphasis)
# -f read from config file, -F write to config dir
# slapcat -b cn=config -f /usr/local/etc/openldap/slapd.conf -F /usr/local/etc/openldap/slapd.d/
/usr/local/sbin/slapcat -n 0 -f /usr/local/etc/openldap/slapd.conf -F /usr/local/etc/openldap/slapd.d/ || true

# import configuration ldif file, uses -c to continue on error, database 0
/usr/local/sbin/slapadd -c -n 0 -F /usr/local/etc/openldap/slapd.d/ -l /usr/local/etc/openldap/slapd.ldif || true

if [ -z "$IMPORTCUSTOM" ] && [ -n "$DEFAULTGROUPS" ]; then
    # Create a default group for people
    < "$TEMPLATEPATH/group.ldif.in" \
       sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
       sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" \
    > /tmp/group.ldif

    # add groups to database 1, uses -c to continue on error
    /usr/local/sbin/slapadd -c -n 1 -F /usr/local/etc/openldap/slapd.d/ -l /tmp/group.ldif || true

    # remove file
    rm -f /tmp/group.ldif

    # if set, adds a generic user with custom password
    if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
        < "$TEMPLATEPATH/genericuser.ldif.in" \
           sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
           sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
           sed "s${sep}%%genericusername%%${sep}$USERNAME${sep}g" | \
           sed "s${sep}%%genericpassword%%${sep}$PASSWORD${sep}g" \
        > /tmp/genericuser.ldif

        # add user to database 1, uses -c to continue on error
        /usr/local/sbin/slapadd -c -n 1 -F /usr/local/etc/openldap/slapd.d/ -l /tmp/genericuser.ldif || true

	# remove file with plaintext password
	rm -f /tmp/genericuser.ldif
    fi
else
    echo "Cannot import custom config AND set default groups"
    echo "Not adding default groups"
    echo "Not adding generic user"
fi

# setup replicator user if remoteip set
if [ -n "$REMOTEIP" ]; then
    < "$TEMPLATEPATH/syncuser.ldif.in" \
    sed "s${sep}%%mysuffix%%${sep}$MYSUFFIX${sep}g" | \
    sed "s${sep}%%mytld%%${sep}$MYTLD${sep}g" | \
    sed "s${sep}%%mycreds%%${sep}$MYCREDS${sep}g" \
    > /tmp/syncuser.ldif

    # add syncuser to database 1, uses -c to continue on error
    /usr/local/sbin/slapadd -c -n 1 -F /usr/local/etc/openldap/slapd.d/ -l /tmp/syncuser.ldif || true

    # remove file with plaintext password
    rm -f /tmp/syncuser.ldif
fi

# create import scripts
cp -f "$TEMPLATEPATH/importldapconfig.sh.in" /root/importldapconfig.sh
chmod +x /root/importldapconfig.sh
cp -f "$TEMPLATEPATH/importldapdata.sh.in" /root/importldapdata.sh
chmod +x /root/importldapdata.sh

# enable service
service slapd enable || true
# sysrc doesn't seem to add this correctly so echo in
#echo "slapd_flags='-4 -h \"ldapi://%2fvar%2frun%2fopenldap%2fldapi/ ldap://$IP/ ldaps://$IP/\"'" >> /etc/rc.conf
# we're setting hostname localldap with external IP in /etc/hosts
echo "slapd_flags='-4 -h \"ldapi://%2fvar%2frun%2fopenldap%2fldapi/ ldap://localldap/ ldaps://localldap/\"'" >> /etc/rc.conf
# set cn=config directory config settings
sysrc slapd_cn_config="YES"
sysrc slapd_sockets="/var/run/openldap/ldapi"
# makes root stuff work, currently unset
# sysrc slapd_owner="DEFAULT"
