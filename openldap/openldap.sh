#!/bin/sh

# Based on POTLUCK TEMPLATE v3.0
# Altered by Michael Gmelin
#
# EDIT THE FOLLOWING FOR NEW FLAVOUR:
# 1. RUNS_IN_NOMAD - true or false
# 2. If RUNS_IN_NOMAD is false, can delete the <flavour>+4 file, else
#    make sure pot create command doesn't include it
# 3. Create a matching <flavour> file with this <flavour>.sh file that
#    contains the copy-in commands for the config files from <flavour>.d/
#    Remember that the package directories don't exist yet, so likely copy
#    to /root
# 4. Adjust package installation between BEGIN & END PACKAGE SETUP
# 5. Adjust jail configuration script generation between BEGIN & END COOK
#    Configure the config files that have been copied in where necessary

# Set this to true if this jail flavour is to be created as a nomad (i.e. blocking) jail.
# You can then query it in the cook script generation below and the script is installed
# appropriately at the end of this script
RUNS_IN_NOMAD=false

# set the cook log path/filename
COOKLOG=/var/log/cook.log

# check if cooklog exists, create it if not
if [ ! -e $COOKLOG ]
then
    echo "Creating $COOKLOG" | tee -a $COOKLOG
else
    echo "WARNING $COOKLOG already exists"  | tee -a $COOKLOG
fi
date >> $COOKLOG

# -------------------- COMMON ---------------

STEPCOUNT=0
step() {
  STEPCOUNT=$(expr "$STEPCOUNT" + 1)
  STEP="$@"
  echo "Step $STEPCOUNT: $STEP" | tee -a $COOKLOG
}

exit_ok() {
  trap - EXIT
  exit 0
}

FAILED=" failed"
exit_error() {
  STEP="$@"
  FAILED=""
  exit 1
}

set -e
trap 'echo ERROR: $STEP$FAILED | (>&2 tee -a $COOKLOG)' EXIT

# -------------- BEGIN PACKAGE SETUP -------------

step "Bootstrap package repo"
mkdir -p /usr/local/etc/pkg/repos
# shellcheck disable=SC2016
#echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest" }' \
echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/quarterly" }' \
  >/usr/local/etc/pkg/repos/FreeBSD.conf
ASSUME_ALWAYS_YES=yes pkg bootstrap

step "Touch /etc/rc.conf"
touch /etc/rc.conf

# this is important, otherwise running /etc/rc from cook will
# overwrite the IP address set in tinirc
step "Remove ifconfig_epair0b from config"
# shellcheck disable=SC2015
sysrc -cq ifconfig_epair0b && sysrc -x ifconfig_epair0b || true

step "Disable sendmail"
service sendmail onedisable

# optionally disable ssh access
#step "Disable sshd"
#service sshd onedisable || true

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

step "Install package sudo"
pkg install -y sudo

step "Install package openssl"
pkg install -y openssl

step "Install package jq"
pkg install -y jq

step "Install package jo"
pkg install -y jo

step "Install package curl"
pkg install -y curl

# openldap25 has missing slap* binaries and other files
step "Install package openldap24-server"
pkg install -y openldap24-server

# should be installed with above
step "Install package openldap24-client"
pkg install -y openldap24-client

step "Install package ldap-account-manager"
pkg install -y ldap-account-manager

step "Install package apache24"
pkg install -y apache24

step "Enable apache24 in /etc/rc.conf"
#sysrc apache24_enable="yes"
service apache24 enable

step "Install package php74"
pkg install -y mod_php74

step "Clean package installation"
pkg clean -y

step "Create necessary directories if they don't exist"
# create some necessary directories
# The database directory MUST exist prior to running slapd AND
# should only be accessible by the slapd and slap tools.
# Mode 700 recommended.
mkdir -p /mnt/openldap-data
mkdir -p /var/db/run/
mkdir -p /usr/local/etc/openldap/slapd.d

step "Set ldap owner on /mnt/openldap-data"
chown -R ldap:ldap /mnt/openldap-data

step "Set 700 permissions on /mnt/openldap-data"
chmod 700 /mnt/openldap-data

step "Set ldap owner on /usr/local/etc/openldap/slapd.d"
chown -R ldap:ldap /usr/local/etc/openldap/slapd.d

# -------------- END PACKAGE SETUP -------------

#
# Create configurations
#

#
# Now generate the run command script "cook"
# It configures the system on the first run by creating the config file(s)
# On subsequent runs, it only starts sleeps (if nomad-jail) or simply exits
#

# clear any old cook runtime file
step "Clean cook artifacts"
rm -rf /usr/local/bin/cook

# this runs when image boots
# ----------------- BEGIN COOK ------------------

step "Create cook script"
echo "#!/bin/sh
RUNS_IN_NOMAD=$RUNS_IN_NOMAD
# declare this again for the pot image, might work carrying variable through like
# with above
COOKLOG=/var/log/cook.log

# No need to change this, just ensures configuration is done only once
if [ -e /usr/local/etc/pot-is-seasoned ]
then
    # If this pot flavour is blocking (i.e. it should not return),
    # we block indefinitely
    if [ \"\$RUNS_IN_NOMAD\" = \"true\" ]
    then
        /bin/sh /etc/rc
        tail -f /dev/null
    fi
    exit 0
fi

# ADJUST THIS: STOP SERVICES AS NEEDED BEFORE CONFIGURATION
#

# stop openldap, shouldn't be running
# will give an error because /usr/local/etc/openldap/slapd.d/cn=config doesn't exist
# grep: /usr/local/etc/openldap/slapd.d/cn=config/olcDatabase=*: No such file or directory
# slapd not running? (check /var/run/openldap/slapd.pid).
#
#/usr/local/etc/rc.d/slapd onestop  || true
service slapd onestop || true

# stop apache, shouldn't be running
#
#/usr/local/etc/rc.d/apache24 onestop  || true
service apache24 onestop || true

# No need to adjust this:
# If this pot flavour is not blocking, we need to read the environment first from /tmp/environment.sh
# where pot is storing it in this case
if [ -e /tmp/environment.sh ]
then
    . /tmp/environment.sh
fi
#
# ADJUST THIS BY CHECKING FOR ALL VARIABLES YOUR FLAVOUR NEEDS:
# Check config variables are set
#
if [ -z \${DOMAIN+x} ]; then
    echo 'DOMAIN is unset - see documentation how to pass in a domain name as a parameter'
    exit 1
fi
if [ -z \${MYCREDS+x} ]; then
    echo 'MYCREDS is unset - see documentation for how to pass in openldap admin password as a parameter'
    exit 1
fi
if [ -z \${HOSTNAME+x} ]; then
    echo 'HOSTNAME is unset - please set a hostname for apache - see documentation for how to pass in the hostname as a parameter'
    exit 1
fi
if [ -z \${IP+x} ]; then
    echo 'IP is unset - please include the IP address - see documentation for how to pass in the IP address as a parameter'
    exit 1
fi
if [ -z \${SERVERID+x} ]; then
    echo 'SERVERID is unset - please include the server id of 001 or 002 - see documentation for how to pass in the server id as a parameter'
    exit 1
fi
if [ -z \${REMOTEIP+x} ]; then
    echo 'REMOTEIP is unset - please include the Remote IP address if this is a multi-master setup - see documentation for how to pass in the remote IP address as a parameter'
fi

#
# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files
#
# Important there MUST be empty lines between the config sections
#


# check that /mnt/openldap-data exists
if [ -d /mnt/openldap-data ]; then
    echo \"INFO: /mnt/openldap-data exists. All good.\"
else
    echo \"ERROR: /mnt/openldap-data does not exist. Where is the persistent storage?\"
    exit 1
fi

# double check permissions on directories
chown -R ldap:ldap /mnt/openldap-data
chmod 700 /mnt/openldap-data
chown -R ldap:ldap /usr/local/etc/openldap/slapd.d

# start certificates config
# setup self-signed certificates before openldap

# openssl self-generated certs
echo \"Creating directory for openldap ssl certificates\"
mkdir -p /usr/local/etc/openldap/private/

echo \"Setting up openldap ssl certificates\"
cd /usr/local/etc/openldap/private/
/usr/bin/openssl req -new -x509 -days 3650 -nodes -keyout ca.key -out /usr/local/etc/openldap/ca.crt -subj \"/C=CC/ST=Province/L=City/O=None/CN=\${DOMAIN}\"
/usr/bin/openssl req -new -nodes  -keyout server.key -out /usr/local/etc/openldap/server.csr -subj \"/C=CC/ST=Province/L=City/O=None/CN=\${DOMAIN}\"
/usr/bin/openssl x509 -req -days 3650 -in /usr/local/etc/openldap/server.csr -out /usr/local/etc/openldap/server.crt -CA /usr/local/etc/openldap/ca.crt -CAkey ca.key -CAcreateserial
/usr/bin/openssl req -nodes -new -keyout client.key -out client.csr -subj \"/C=CC/ST=Province/L=City/O=None/CN=\${DOMAIN}\"
/usr/bin/openssl x509 -req -days 3650 -in client.csr -out /usr/local/etc/openldap/client.crt -CA /usr/local/etc/openldap/ca.crt -CAkey ca.key
cd ~

# end certificates config

# start ldap config

# create local syslog dir
echo \"Creating custom syslog parameters for slapd\"
touch /var/log/slapd.log
mkdir -p /usr/local/etc/syslog.d/
echo \"# openldap pot image additions
!slapd
*.*                                                           /var/log/slapd.log\" > /usr/local/etc/syslog.d/slapd.conf
# restart syslog and sleep
service syslogd restart
sleep 5

# split domain into parts
MYSUFFIX=\$(echo \${DOMAIN} | awk -F '.' 'NF>=2 {print \$(NF-1)}')
MYTLD=\$(echo \${DOMAIN} | awk -F '.' 'NF>=2 {print \$(NF)}')
echo \"From DOMAIN of \${DOMAIN} we get MYSUFFIX of \${MYSUFFIX} and MYTLD of \${MYTLD}\"

# multi-master setup for slapd.conf
# if we have a value for remoteip and a value for server id, set a server id and append the multimaster setup
# to slapd.conf
if [ ! -z \${REMOTEIP+x} ]; then
    # set server id
    /usr/bin/sed -i .orig \"s|# serverID SETSERVERID|serverID \${SERVERID}|g\" /root/slapd.conf
    # set root dn
    /usr/bin/sed -i .orig \"s|dc=MYSUFFIX,dc=MYTLD|dc=\${MYSUFFIX},dc=\${MYTLD}|g\" /root/slapd.conf

    # append multimaster config to slapd.conf
    echo \"syncrepl rid=000
 provider=ldap://\${REMOTEIP}
 type=refreshAndPersist
 retry=\\\"5 5 300 +\\\"
 searchbase=\\\"dc=\${MYSUFFIX},dc=\${MYTLD}\\\"
 attrs=\\\"*,+\\\"
 bindmethod=simple
 binddn=\\\"cn=Manager,dc=\${MYSUFFIX},dc=\${MYTLD}\\\"
 credentials=ofcsecret

# Indices to maintain
index default pres,eq
index uid,memberUid,gidNumber

# Create indexes for attribute cn (commonname) and givenName
# EQUALITY, SUBSTR searches and provides optimization
# for sc=a* type searches
index cn,givenName eq,sub,subinitial

# Create indexes for sn (surname) on EQUALITY and SUBSTR searches
index sn eq,sub

# Creates indexes for attribute mail on presence, EQUALITY and SUBSTR
index mail pres,eq,sub

# Optimises searches of form objectclass=person
# index objectclass eq
# already added

# Syncprov indexes
index entryCSN eq
index entryUUID eq
# Mirror mode essential to allow writes and must appear after all syncrepl directives
mirrormode TRUE

# Define the provider to use the syncprov overlay (last directives in database section)
overlay syncprov

# contextCSN saved to database every 100 updates or 10 mins.
syncprov-checkpoint 100 10
syncprov-sessionlog 100\" >> /root/slapd.conf

    echo \"Copying in custom slapd.conf with back_mdb enabled and multiserver setup\"
    cp -f /root/slapd.conf /usr/local/etc/openldap/slapd.conf
else
    # copy over slapd.conf without cluster config
    echo \"No variables set for REMOTEIP \${REMOTEIP} and SERVERID \${SERVERID}, single server setup only\"
    # set root dn
    /usr/bin/sed -i .orig \"s|dc=MYSUFFIX,dc=MYTLD|dc=\${MYSUFFIX},dc=\${MYTLD}|g\" /root/slapd.conf
    echo \"Copying in custom slapd.conf with back_mdb enabled for single server setup\"
    cp -f /root/slapd.conf /usr/local/etc/openldap/slapd.conf
fi

# set owner ldap:ldap on /usr/local/etc/openldap/slapd.conf
echo \"Setting ldap owner on /usr/local/etc/openldap/slapd.conf\"
chown ldap:ldap /usr/local/etc/openldap/slapd.conf

# make sure not world-readable
echo \"Removing world-readable settings on /usr/local/etc/openldap/slapd.conf\"
chmod o-rwx /usr/local/etc/openldap/slapd.conf

# create password
if [ -x /usr/local/sbin/slappasswd ]; then
    SETSLAPPASS=\$(/usr/local/sbin/slappasswd -s \${MYCREDS})
    echo \"Generated slappassword output is \${SETSLAPPASS}\"
fi

# Setup default slapd.ldif
echo \"Generating /usr/local/etc/openldap/slapd.ldif\"

echo \"# This file should NOT be world readable.
dn: cn=config
objectClass: olcGlobal
cn: config
olcArgsFile: /var/db/run/slapd.args
olcPidFile: /var/db/run/slapd.pid
#olcSecurity: ssf=1 update_ssf=112 simple_bind=64
# enable 128 bit TLS
olcSecurity: ssf=128
olcTLSCACertificatePath: /usr/local/etc/openldap/
olcTLSCertificateFile: /usr/local/etc/openldap/server.crt
olcTLSCertificateKeyFile: /usr/local/etc/openldap/private/server.key
olcTLSCACertificateFile: /usr/local/etc/openldap/ca.crt
olcTLSCipherSuite: HIGH:MEDIUM:+SSLv3
olcTLSProtocolMin: 3.1
olcTLSVerifyClient: never
structuralObjectClass: olcGlobal

dn: cn=schema,cn=config
objectClass: olcSchemaConfig
cn: schema

include: file:///usr/local/etc/openldap/schema/core.ldif
include: file:///usr/local/etc/openldap/schema/cosine.ldif
include: file:///usr/local/etc/openldap/schema/inetorgperson.ldif
include: file:///usr/local/etc/openldap/schema/nis.ldif

dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulepath: /usr/local/libexec/openldap
olcModuleload: back_mdb.la

dn: olcDatabase=frontend,cn=config
objectClass: olcDatabaseConfig
objectClass: olcFrontendConfig
olcDatabase: frontend
olcAccess: to * by * read

dn: olcDatabase=config,cn=config
objectClass: olcDatabaseConfig
olcDatabase: config
olcRootDN: cn=Manager,cn=config
# generate a password by running slappasswd
# sample pass is password, set a new password with slappasswd
# and replace text here
olcRootPW: \${SETSLAPPASS}
olcMonitoring: FALSE
olcAccess: to * by * none

# LMDB database definitions
dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcSuffix: dc=\${MYSUFFIX},dc=\${MYTLD}
olcRootDN: cn=Manager,dc=\${MYSUFFIX},dc=\${MYTLD}
# generate a password by running slappasswd
# sample pass is password, set a new password with slappasswd
# and replace text here
olcRootPW: \${SETSLAPPASS}
olcDbDirectory: /mnt/openldap-data
olcDbIndex: objectClass eq
\" > /usr/local/etc/openldap/slapd.ldif

# set owner ldap
echo \"Setting ldap owner on /usr/local/etc/openldap/slapd.ldif\"
chown ldap:ldap /usr/local/etc/openldap/slapd.ldif
#

# make sure not world-readable
#
echo \"Removing world-readable settings on /usr/local/etc/openldap/slapd.ldif\"
chmod o-rwx /usr/local/etc/openldap/slapd.ldif
#

echo \"Generating /usr/local/etc/openldap/ldap.conf\"
echo \"
#BASE    dc=domain,dc=com
#URI     ldap:// ldaps://
BASE    dc=\${MYSUFFIX},dc=\${MYTLD}
URI     ldap://\${IP} ldaps://\${IP}
SIZELIMIT       0
TIMELIMIT       15
DEREF          never
TLS_CACERT /usr/local/etc/openldap/ca.crt
TLS_CIPHER_SUITE HIGH:MEDIUM:+SSLv3\" >> /usr/local/etc/openldap/ldap.conf

# set perms
chown ldap:ldap /usr/local/etc/openldap/ldap.conf
chmod 644 /usr/local/etc/openldap/ldap.conf

# remove any old config
#
echo \"Removing old openldap config data in /usr/local/etc/openldap/slapd.d/\"
rm -r /usr/local/etc/openldap/slapd.d/*
#

# set permissions so that ldap user owns /usr/local/etc/openldap/slapd.d/
# this is critical to making the below work
#
echo \"Setting ldap owner on /usr/local/etc/openldap/slapd.d/\"
chown -R ldap:ldap /usr/local/etc/openldap/slapd.d/
#

# build a basic config from the included slapd.CONF file (capitalised for emphasis)
# -f read from config file, -F write to config dir
# slapcat -b cn=config -f /usr/local/etc/openldap/slapd.conf -F /usr/local/etc/openldap/slapd.d/
#
echo \"Building simple configuration file\"
/usr/local/sbin/slapcat -n 0 -f /usr/local/etc/openldap/slapd.conf -F /usr/local/etc/openldap/slapd.d/
#

#
# import configuration ldif file, uses -c to continue on error, database 0
echo \"Importing configuration ldif\"
/usr/local/sbin/slapadd -c -n 0 -F /usr/local/etc/openldap/slapd.d/ -l /usr/local/etc/openldap/slapd.ldif
#

# create import scripts
echo \"Creating config import script: /root/importldapconfig.sh\"
echo \"#!/bin/sh
if [ -f /root/config.ldif ]; then
    /usr/local/sbin/slapadd -c -n 0 -F /usr/local/etc/openldap/slapd.d/ -l /root/config.ldif
fi\" > /root/importldapconfig.sh

# setting execute perms
chmod +x /root/importldapconfig.sh

# create import data script
echo \"Creating data import script: /root/importldapdata.sh\"
echo \"#!/bin/sh
if [ -f /root/data.ldif ]; then
    /usr/local/sbin/slapadd -c -n 1 -F /usr/local/etc/openldap/slapd.d/ -l /root/data.ldif
fi\" > /root/importldapdata.sh

# setting execute perms
chmod +x /root/importldapdata.sh

# enable openldap and set config options
#
echo \"Enabling slapd service\"
service slapd enable
# sysrc doesn't seem to add this correctly so echo in
echo \"slapd_flags='-4 -h \\\"ldapi://%2fvar%2frun%2fopenldap%2fldapi/ ldap://\${IP}/ ldaps://\${IP}/\\\"'\" >> /etc/rc.conf
# set cn=config directory config settings
sysrc slapd_cn_config=\"YES\"
sysrc slapd_sockets=\"/var/run/openldap/ldapi\"
# makes root stuff work, currently unset
# sysrc slapd_owner=\"DEFAULT\"

# to-do
# set backup to /mnt/openldap-settings
# add a script to crontab which runs slapcat
# and outputs to a second mount in persistent storage

# end openldap config

# start apache24 config

# Adjust document root to /usr/local/www/lam in /usr/local/etc/apache24/httpd.conf
# /usr/local/www/apache24/data appears twice only, so simple sed replace of both should suffice
#
if [ -f /usr/local/etc/apache24/httpd.conf ]; then
    echo \"Changing document root for apache to openldap lam\"
    /usr/bin/sed -i .orig 's|/usr/local/www/apache24/data|/usr/local/www/lam|g' /usr/local/etc/apache24/httpd.conf

    echo \"Setting Listen to \${IP}:80\"
    /usr/bin/sed -i .orig \"s|Listen 80|Listen \${IP}:80|g\" /usr/local/etc/apache24/httpd.conf

    echo \"Setting ServerName to \${HOSTNAME}:80\"
    /usr/bin/sed -i .orig \"s|#ServerName www.example.com:80|ServerName \${HOSTNAME}:80|g\" /usr/local/etc/apache24/httpd.conf

    # adjust /usr/local/etc/apache24/httpd.conf and replace <IfModule dir_module> with the following content:
    # note: we can simply append to the httpd.conf file and it will overwrite prior values
    #
    echo \"Making other changes to httpd.conf\"
    echo \"
<IfModule dir_module>
    DirectoryIndex index.php index.html
    <FilesMatch \\\"\.php$\\\">
        SetHandler application/x-httpd-php
     </FilesMatch>
    <FilesMatch \\\"\.phps$\\\">
        SetHandler application/x-httpd-php-source
    </FilesMatch>
</IfModule>\" >> /usr/local/etc/apache24/httpd.conf
fi
#

# end apache24 config #

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION
echo \"Starting openldap and apache\"
service slapd start
service apache24 restart

#
# Do not touch this:
touch /usr/local/etc/pot-is-seasoned

# If this pot flavour is blocking (i.e. it should not return), there is no /tmp/environment.sh
# created by pot and we now after configuration block indefinitely
if [ \"\$RUNS_IN_NOMAD\" = \"true\" ]
then
    /bin/sh /etc/rc
    tail -f /dev/null
fi
" > /usr/local/bin/cook

# ----------------- END COOK ------------------


# ---------- NO NEED TO EDIT BELOW ------------

step "Make cook script executable"
if [ -e /usr/local/bin/cook ]
then
    echo "setting executable bit on /usr/local/bin/cook" | tee -a $COOKLOG
    chmod u+x /usr/local/bin/cook
else
    exit_error "there is no /usr/local/bin/cook to make executable"
fi

#
# There are two ways of running a pot jail: "Normal", non-blocking mode and
# "Nomad", i.e. blocking mode (the pot start command does not return until
# the jail is stopped).
# For the normal mode, we create a /usr/local/etc/rc.d script that starts
# the "cook" script generated above each time, for the "Nomad" mode, the cook
# script is started by pot (configuration through flavour file), therefore
# we do not need to do anything here.
#

# Create rc.d script for "normal" mode:
step "Create rc.d script to start cook"
echo "creating rc.d script to start cook" | tee -a $COOKLOG

echo "#!/bin/sh
#
# PROVIDE: cook
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
. /etc/rc.subr
name=\"cook\"
rcvar=\"cook_enable\"
load_rc_config \$name
: \${cook_enable:=\"NO\"}
: \${cook_env:=\"\"}
command=\"/usr/local/bin/cook\"
command_args=\"\"
run_rc_command \"\$1\"
" > /usr/local/etc/rc.d/cook

step "Make rc.d script to start cook executable"
if [ -e /usr/local/etc/rc.d/cook ]
then
  echo "Setting executable bit on cook rc file" | tee -a $COOKLOG
  chmod u+x /usr/local/etc/rc.d/cook
else
  exit_error "/usr/local/etc/rc.d/cook does not exist"
fi

if [ "$RUNS_IN_NOMAD" != "true" ]
then
  step "Enable cook service"
  # This is a non-nomad (non-blocking) jail, so we need to make sure the script
  # gets started when the jail is started:
  # Otherwise, /usr/local/bin/cook will be set as start script by the pot flavour
  echo "enabling cook" | tee -a $COOKLOG
  service cook enable
fi

# -------------------- DONE ---------------
exit_ok
