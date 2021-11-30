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
  STEPCOUNT=$(("$STEPCOUNT" + 1))
  STEP="$*"
  echo "Step $STEPCOUNT: $STEP" | tee -a $COOKLOG
}

exit_ok() {
  trap - EXIT
  exit 0
}

FAILED=" failed"
exit_error() {
  STEP="$*"
  FAILED=""
  exit 1
}

set -e
trap 'echo ERROR: $STEP$FAILED | (>&2 tee -a $COOKLOG)' EXIT

# -------------- BEGIN PACKAGE SETUP -------------

step "Bootstrap package repo"
mkdir -p /usr/local/etc/pkg/repos
# only modify repo if not already done in base image
# shellcheck disable=SC2016
test -e /usr/local/etc/pkg/repos/FreeBSD.conf || \
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

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

# we need consul for consul agent
step "Install package consul"
pkg install -y consul

step "Install package node_exporter"
pkg install -y node_exporter

step "Install package sudo"
pkg install -y sudo

step "Install package curl"
pkg install -y curl

step "Install package jq"
pkg install -y jq

step "Install package jo"
pkg install -y jo

step "Install package syslog-ng"
pkg install -y syslog-ng

step "Install package vault"
pkg install -y vault

step "Install package influxdb"
pkg install -y influxdb

step "Clean package installation"
pkg clean -y

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
step "Remove pre-existing cook script (if any)"
rm -f /usr/local/bin/cook

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
# not needed, not started automatically, needs configuring

# No need to adjust this:
# If this pot flavour is not blocking, we need to read the environment first from /tmp/environment.sh
# where pot is storing it in this case
if [ -e /tmp/environment.sh ]
then
    . /tmp/environment.sh
fi

#
# ADJUST THIS BY CHECKING FOR ALL VARIABLES YOUR FLAVOUR NEEDS:
#

# Check config variables are set
#
if [ -z \${DATACENTER+x} ]; then
    echo 'DATACENTER is unset - see documentation to configure this flavour with the datacenter name. This parameter is mandatory.'
    exit 1
fi
if [ -z \${NODENAME+x} ];
then
    echo 'NODENAME is unset - see documentation to configure this flavour with a name for this node. This parameter is mandatory.'
    exit 1
fi
if [ -z \${CONSULSERVERS+x} ]; then
    echo 'CONSULSERVERS is unset - please pass in one or more correctly-quoted, comma-separated addresses for consul peer IPs. Refer to documentation. This parameter is mandatory.'
    exit 1
fi
if [ -z \${IP+x} ]; then
    echo 'IP is unset - see documentation to configure this flavour for an IP address. This parameter is mandatory.'
    exit 1
fi
if [ -z \${VAULTSERVER+x} ];
then
    echo 'VAULTSERVER is unset - see documentation to set the vault server IP address. This is required to obtain certificates. This parameter is mandatory.'
    exit 1
fi
# we need a token from the vault server
if [ -z \${VAULTTOKEN+x} ];
then
    echo 'VAULTTOKEN is unset - a vault token is required to obtain certificates. Refer to documentation. This parameter is mandatory.'
    exit 1
fi
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen for the consul flavour.
# Re-used for nomad, which is usually 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the one from the consul flavour
if [ -z \${GOSSIPKEY+x} ];
then
    echo 'GOSSIPKEY is unset - please provide a 32 byte base64 key from the (consul keygen key) command. This parameter is mandatory.'
    exit 1
fi
# optional logging to remote syslog server
if [ -z \${REMOTELOG+x} ];
then
    echo 'REMOTELOG is unset - please provide the IP address of a loki server, or set a null value. This parameter is optional.'
    REMOTELOG=\"null\"
fi
# sftpuser credentials
if [ -z \${SFTPUSER+x} ];
then
    echo 'SFTPUSER is unset - please provide a username to use for the SFTP user on the vault leader. This parameter is mandatory.'
    exit 1
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# add group for accessing certs (shared between services)
/usr/sbin/pw groupadd certaccess

# some basic ssh setup
echo \"Initialising ssh settings\"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys

if [ -f /root/sshkey ] && [ ! -f /root/.ssh/id_rsa ]; then
    cp /root/sshkey /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    ssh-keygen -f /root/.ssh/id_rsa -y > /root/.ssh/id_rsa.pub
fi

# setup temp directory for temp certs
mkdir -p /tmp/tmpcerts

# echo a message to user
echo \"\"
echo \"########################### IMPORTANT NOTICE ###########################\"
echo \"\"
echo \"Make sure to copy in id_rsa from vault leader certuser instance!\"
echo \"\"
echo \"########################################################################\"
echo \"\"
# end client

# retrieve first round of certificates from vault leader via sftp
echo \"Get first round of certificates from vault leader via sftp\"
if [ -f /root/.ssh/id_rsa ]; then
    cd /tmp/tmpcerts
    # wildcard retrieval works manually but not in the script, so we specify each file to retrieve
    /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTSERVER:\$IP/cert.pem
    (umask 137; /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTSERVER:\$IP/key.pem)
    chgrp certaccess key.pem
    /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTSERVER:\$IP/ca.pem
    /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTSERVER:\$IP/combinedca.pem
    cd ~
fi

# setup directories for vault usage
mkdir -p /mnt/templates
mkdir -p /mnt/certs/hash
chgrp -R certaccess /mnt/certs
mkdir -p /mnt/vault

## start consul

# make consul configuration directory and set permissions
mkdir -p /usr/local/etc/consul.d
chmod 750 /usr/local/etc/consul.d

# Create the consul agent config file with imported variables
echo \"{
 \\\"advertise_addr\\\": \\\"\$IP\\\",
 \\\"datacenter\\\": \\\"\$DATACENTER\\\",
 \\\"node_name\\\": \\\"\$NODENAME\\\",
 \\\"data_dir\\\":  \\\"/var/db/consul\\\",
 \\\"dns_config\\\": {
  \\\"a_record_limit\\\": 3,
  \\\"enable_truncate\\\": true
 },
 \\\"verify_incoming\\\": true,
 \\\"verify_outgoing\\\": true,
 \\\"verify_server_hostname\\\":false,
 \\\"verify_incoming_rpc\\\": true,
 \\\"ca_file\\\": \\\"/mnt/certs/combinedca.pem\\\",
 \\\"cert_file\\\": \\\"/mnt/certs/cert.pem\\\",
 \\\"key_file\\\": \\\"/mnt/certs/key.pem\\\",
 \\\"log_file\\\": \\\"/var/log/consul/\\\",
 \\\"log_level\\\": \\\"WARN\\\",
 \\\"encrypt\\\": \\\"\$GOSSIPKEY\\\",
 \\\"start_join\\\": [ \$CONSULSERVERS ],
 \\\"telemetry\\\": {
  \\\"prometheus_retention_time\\\": \\\"24h\\\",
  \\\"disable_hostname\\\": true
 },
 \\\"service\\\": {
  \\\"address\\\": \\\"\$IP\\\",
  \\\"name\\\": \\\"node-exporter\\\",
  \\\"tags\\\": [\\\"_app=prometheus\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\", \\\"_datacenter=\$DATACENTER\\\"],
  \\\"port\\\": 9100
 }
}\" | (umask 177; cat > /usr/local/etc/consul.d/agent.json)

# set owner on /usr/local/etc/consul.d
chown -R consul:wheel /usr/local/etc/consul.d

# enable consul
service consul enable

# set load parameter for consul config
sysrc consul_args=\"-config-file=/usr/local/etc/consul.d/agent.json\"

# setup consul logs, might be redundant if not specified in agent.json above
mkdir -p /var/log/consul
touch /var/log/consul/consul.log
chown -R consul:wheel /var/log/consul

# add the consul user to the certaccess group
/usr/sbin/pw usermod consul -G certaccess

## end consul

## start Vault

# first remove any existing vault configuration
if [ -f /usr/local/etc/vault/vault-server.hcl ]; then
    rm /usr/local/etc/vault/vault-server.hcl
fi
# then setup a fresh vault.hcl specific to the type of image

# default freebsd vault.hcl is /usr/local/etc/vault.hcl and
# the init script /usr/local/etc/rc.d/vault refers to this
# but many vault docs refer to /usr/local/etc/vault/vault-server.hcl
# or similar

# begin vault config
# we're setting a config file but not actually running the vault service
# certificate rotation is being done with a cron job
# token rotation may require the vault service

echo \"disable_mlock = true
ui = false
vault {
  address = \\\"\$VAULTSERVER:8200\\\"
  retry {
    num_retries = 5
  }
}
storage \\\"file\\\" {
  path = \\\"/mnt/vault/data\\\"
}
#template {
#  source = \\\"/mnt/templates/cert.tpl\\\"
#  destination = \\\"/mnt/certs/cert.pem\\\"
#}
#template {
#  source = \\\"/mnt/templates/ca.tpl\\\"
#  destination = \\\"/mnt/certs/ca.pem\\\"
#}
#template {
#  source = \\\"/mnt/templates/key.tpl\\\"
#  destination = \\\"/mnt/certs/key.pem\\\"
#}\" | (umask 177; cat > /usr/local/etc/vault.hcl)

# Set permission for vault.hcl, so that vault can read it
chown vault:wheel /usr/local/etc/vault.hcl

# setup template files for certificates
echo \"{{- /* /mnt/templates/cert.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$NODENAME\\\" \\\"ttl=24h\\\" \\\"alt_names=\$NODENAME\\\" \\\"ip_sans=\$IP\\\" }}
{{ .Data.certificate }}{{ end }}
\" > /mnt/templates/cert.tpl

echo \"{{- /* /mnt/templates/ca.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$NODENAME\\\" }}
{{ .Data.issuing_ca }}{{ end }}
\" > /mnt/templates/ca.tpl

echo \"{{- /* /mnt/templates/key.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$NODENAME\\\" \\\"ttl=24h\\\" \\\"alt_names=\$NODENAME\\\" \\\"ip_sans=\$IP\\\" }}
{{ .Data.private_key }}{{ end }}
\" > /mnt/templates/key.tpl

# set permissions on /mnt for vault data
chown -R vault:wheel /mnt/vault

# invite to certaccess group
/usr/sbin/pw usermod vault -G certaccess

# setup rc.conf entries
# we do not set vault_user=vault because vault will not start
# we're not starting vault as a service
service vault enable
sysrc vault_login_class=root
sysrc vault_syslog_output_enable=\"YES\"
sysrc vault_syslog_output_priority=\"warn\"

# new CA cert retrieval process with curl
echo \"Retrieving CA certificates from Vault leader\"
# get the root CA
/usr/local/bin/curl --silent --cacert /tmp/tmpcerts/ca.pem --cert /tmp/tmpcerts/cert.pem --key /tmp/tmpcerts/key.pem -o /mnt/certs/CA_cert.pem https://\$VAULTSERVER:8200/v1/pki/ca/pem
# append a new line to the file, as will concat together later with another file
if [ -s /mnt/certs/CA_cert.pem ]; then
    echo \"\" >> /mnt/certs/CA_cert.pem
fi
# get the intermediate CA
/usr/local/bin/curl --silent --cacert /tmp/tmpcerts/ca.pem --cert /tmp/tmpcerts/cert.pem --key /tmp/tmpcerts/key.pem -o /mnt/certs/intermediate.cert.pem https://\$VAULTSERVER:8200/v1/pki_int/ca/pem
# append a new line to the file, as will concat together later with another file
if [ -s /mnt/certs/intermediate.cert.pem ]; then
    echo \"\" >> /mnt/certs/intermediate.cert.pem
fi
# validate the certificates
echo \"Validating CA certificates\"
if [ -s /mnt/certs/CA_cert.pem ] && [ -s /mnt/certs/intermediate.cert.pem ]; then
    /usr/bin/openssl verify -CAfile /mnt/certs/CA_cert.pem /mnt/certs/intermediate.cert.pem
fi

# unwrap the pki token issued by vault leader
echo \"Unwrapping passed in token...\"
(umask 177; /usr/local/bin/vault unwrap -address=https://\$VAULTSERVER:8200 -client-cert=/tmp/tmpcerts/cert.pem -client-key=/tmp/tmpcerts/key.pem -ca-cert=/mnt/certs/intermediate.cert.pem -format=json \$VAULTTOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/unwrapped.token)
sleep 1
if [ -s /root/unwrapped.token ]; then
    echo \"Token unwrapped\"
    THIS_TOKEN=\$(/bin/cat /root/unwrapped.token)
    echo \"Logging in to vault leader to authenticate\"
    (umask 177; echo \"\$THIS_TOKEN\" | /usr/local/bin/vault login -address=https://\$VAULTSERVER:8200 -client-cert=/tmp/tmpcerts/cert.pem -client-key=/tmp/tmpcerts/key.pem -ca-cert=/mnt/certs/intermediate.cert.pem -method=token -field=token token=- > /root/login.token)
fi

# get list of secrets engines (helps cluster to align)
/usr/local/bin/vault secrets list -address=https://\$VAULTSERVER:8200 -client-cert=/tmp/tmpcerts/cert.pem -client-key=/tmp/tmpcerts/key.pem -ca-cert=/mnt/certs/intermediate.cert.pem

echo \"Setting certificate payload\"
if [ -s /root/login.token ]; then
    # generate certificates to use
    # using this payload.json approach to avoid nested single and double quotes for expansion
    # new way of generating payload.json with jo
    /usr/local/bin/jo -p common_name=\$IP alt_names=\$NODENAME ttl=24h ip_sans=\"\$IP,127.0.0.1\" format=pem > /mnt/templates/payload.json
    # we use curl to get the certificates in json format as the issue command only has formats: pem, pem_bundle, der
    # but no json format except via the API
    echo \"Generating certificates to use from Vault\"
    HEADER=\$(/bin/cat /root/login.token)
    (umask 177; /usr/local/bin/curl --cacert /tmp/tmpcerts/combinedca.pem --cert /tmp/tmpcerts/cert.pem --key /tmp/tmpcerts/key.pem --header \"X-Vault-Token: \$HEADER\" --request POST --data @/mnt/templates/payload.json https://\$VAULTSERVER:8200/v1/pki_int/issue/\$DATACENTER > /mnt/certs/vaultissue.json)
    # extract the required certificates to individual files
    /usr/local/bin/jq -r '.data.certificate' /mnt/certs/vaultissue.json > /mnt/certs/cert.pem
    # append the ca cert to the cert
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json >> /mnt/certs/cert.pem
    (umask 137; /usr/local/bin/jq -r '.data.private_key' /mnt/certs/vaultissue.json > /mnt/certs/key.pem)
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json > /mnt/certs/ca.pem
    cd /mnt/certs
    # concat the root CA and intermediary CA into combined file
    cat /mnt/certs/CA_cert.pem /mnt/certs/ca.pem > /mnt/certs/combinedca.pem
    # steps here to hash ca, required for syslog-ng
    ln -s ca.pem hash/\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/ca.pem).0
    ln -s combinedca.pem hash/\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/combinedca.pem).0
    cd /root
    # set permissions on /mnt/certs for vault
    chown -R vault:certaccess /mnt/certs
    # Setting root:certaccess and 0640 on key across images
    chown root:certaccess /mnt/certs/key.pem
    chmod 640 /mnt/certs/key.pem
    # validate the certificates
    echo \"Validating client certificate\"
    if [ -s /mnt/certs/combinedca.pem ] && [ -s /mnt/certs/cert.pem ]; then
        /usr/bin/openssl verify -CAfile /mnt/certs/combinedca.pem /mnt/certs/cert.pem
    fi

    # setup certificate rotation script
    echo \"Setting up certificate rotation script\"
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
if [ -s /root/login.token ]; then
    LOGINTOKEN=\\\$(/bin/cat /root/login.token)
    HEADER=\\\$(echo \\\"X-Vault-Token: \\\"\\\$LOGINTOKEN)
    (umask 177; /usr/local/bin/curl --cacert /mnt/certs/combinedca.pem --cert /mnt/certs/cert.pem --key /mnt/certs/key.pem --header \\\"\\\$HEADER\\\" --request POST --data @/mnt/templates/payload.json https://\$VAULTSERVER:8200/v1/pki_int/issue/\$DATACENTER > /mnt/certs/vaultissue.json)
    # extract the required certificates to individual files
    /usr/local/bin/jq -r '.data.certificate' /mnt/certs/vaultissue.json > /mnt/certs/cert.pem
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json >> /mnt/certs/cert.pem
    (umask 137; /usr/local/bin/jq -r '.data.private_key' /mnt/certs/vaultissue.json > /mnt/certs/key.pem)
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json > /mnt/certs/ca.pem
    cd /mnt/certs
    # concat the root CA and intermediary CA into combined file
    cat CA_cert.pem ca.pem > combinedca.pem
    # steps here to hash ca
    ln -s ca.pem hash\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/ca.pem).0
    ln -s combinedca.pem hash\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/combinedca.pem).0
    cd /root
    # set permissions on /mnt/certs for vault
    chown -R vault:certaccess /mnt/certs
    # Setting root:certaccess and 0640 on key across images
    chown root:certaccess /mnt/certs/key.pem
    chmod 640 /mnt/certs/key.pem
    # restart services
    service consul reload
    service consul status || service consul start
    service syslog-ng restart
    service influxd reload
else
    echo "/root/login.token does not contain a token. Certificates cannot be renewed."
fi
\" > /root/rotate-certs.sh

    if [ -f /root/rotate-certs.sh ]; then
        # make executable
        chmod +x /root/rotate-certs.sh
        # add a crontab entry for every hour
        echo \"0 * * * * root /root/rotate-certs.sh >> /mnt/rotate-cert.log 2>&1\" >> /etc/crontab
    fi

    # setup syslog-ng
    # optional remote logging
    if [ ! -z \$REMOTELOG ] && [ \$REMOTELOG != \"null\" ]; then
        if [ -f /root/syslog-ng.conf ]; then
            /usr/bin/sed -i .orig \"s/REMOTELOGIP/\$REMOTELOG/g\" /root/syslog-ng.conf
            cp -f /root/syslog-ng.conf /usr/local/etc/syslog-ng.conf
            # stop syslogd
            service syslogd onestop || true
            # setup sysrc entries to start and set parameters to accept logs from remote subnet
            sysrc syslogd_enable=\"NO\"
            sysrc syslog_ng_enable=\"YES\"
            #sysrc syslog_ng_flags=\"-u daemon\"
            sysrc syslog_ng_flags=\"-R /tmp/syslog-ng.persist\"
            /usr/local/etc/rc.d/syslog-ng start
            echo \"syslog-ng setup complete\"
        else
            echo \"/root/syslog-ng.conf is missing?\"
        fi
    else
        echo \"REMOTELOG parameter is not set to an IP address. syslog-ng won't operate.\"
    fi

    # make some needed directories
    mkdir -p /mnt/influxdb/meta
    mkdir -p /mnt/influxdb/data
    mkdir -p /mnt/influxdb/wal

	# add the influxd user to the certaccess group
	/usr/sbin/pw usermod influxd -G certaccess

    # set IP in influxdb.conf and then copy to /usr/local/etc
    if [ -f /root/influxdb.conf ]; then
        /usr/bin/sed -i .orig \"s/MYIP/\$IP/g\" /root/influxdb.conf
        cp -f /root/influxdb.conf /usr/local/etc/influxdb.conf
    fi

    # set perms
    chown -R influxd:influxd /mnt/influxdb

    # set startup options
    service influxd enable

    # end influxdb

    # start consul agent
    service consul start

    # start influxdb
    service influxd start

else
    echo \"ERROR: There was a problem logging into vault and no certificates were retrieved. Vault not started.\"
fi

# node exporter needs tls setup
echo \"tls_server_config:
  cert_file: /mnt/certs/cert.pem
  key_file: /mnt/certs/key.pem
\" > /usr/local/etc/node-exporter.yml

# enable node_exporter service
# add node_exporter user
/usr/sbin/pw useradd -n nodeexport -c 'nodeexporter user' -m -s /usr/bin/nologin -h -

# invite node_exporter to certaccess group
/usr/sbin/pw usermod nodeexport -G certaccess

# enable node_exporter service
service node_exporter enable
sysrc node_exporter_args=\"--web.config=/usr/local/etc/node-exporter.yml\"
sysrc node_exporter_user=nodeexport
sysrc node_exporter_group=nodeexport

# start node_exporter
service node_exporter start

#
# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# start services


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
