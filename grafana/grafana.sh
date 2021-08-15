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
#echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest" }' \
echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/quarterly" }' \
  >/usr/local/etc/pkg/repos/FreeBSD.conf
ASSUME_ALWAYS_YES=yes pkg bootstrap

step "Touch /etc/rc.conf"
touch /etc/rc.conf

# this is important, otherwise running /etc/rc from cook will
# overwrite the IP address set in tinirc
step "Remove ifconfig_epair0b from config"
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

step "Install package grafana7"
pkg install -y grafana7

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
    echo 'DATACENTER is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${NODENAME+x} ];
then
    echo 'NODENAME is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${CONSULSERVERS+x} ]; then
    echo 'CONSULSERVERS is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${IP+x} ]; then
    echo 'IP is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${VAULTSERVER+x} ];
then
    echo 'VAULTSERVER is unset - you must include the master vault server IP'
    exit 1
fi
# we need a token from the vault server
if [ -z \${VAULTTOKEN+x} ];
then
    echo 'VAULTTOKEN is unset - see documentation how to configure this flavour. You must pass in a valid token'
    exit 1
fi
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen for the consul flavour.
# Re-used for nomad, which is usually 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the one from the consul flavour
if [ -z \${GOSSIPKEY+x} ];
then
    echo 'GOSSIPKEY is unset - see documentation how to configure this flavour, defaulting to preset encrypt key. Do not use this in production!'
    GOSSIPKEY='\"BY+vavBUSEmNzmxxS3k3bmVFn1giS4uEudc774nBhIw=\"'
fi
# required prometheus server
if [ -z \${PROMSOURCE+x} ];
then
    echo 'PROMSOURCE is unset - see documentation how to configure this flavour with IP address of Prometheus host. Exiting.'
    exit 1
fi
# required loki server
if [ -z \${LOKISOURCE+x} ];
then
    echo 'LOKISOURCE is unset - see documentation how to configure this flavour with IP address of Loki host. Exiting.'
    exit 1
fi
# required influxdb server
if [ -z \${INFLUXDBSOURCE+x} ];
then
    echo 'INFLUXDBSOURCE is unset - see documentation how to configure this flavour with IP address of InfluxDB host. Exiting.'
    exit 1
fi
# required influxdb server
if [ -z \${INFLUXDATABASE+x} ];
then
    echo 'INFLUXDATABASE is unset - see documentation how to configure this flavour with InfluxDB datanase name. Defaulting to default'
    INFLUXDATABASE=\"default\"
fi
# grafana credentials
if [ -z \${GRAFANAUSER+x} ];
then
    echo 'GRAFANAUSER is unset - see documentation how to configure this flavour with credentials. Defaulting to admin'
    GRAFANAUSER=admin
fi
if [ -z \${GRAFANAPASSWORD+x} ];
then
    echo 'GRAFANAPASSWORD is unset - see documentation how to configure this flavour with credentials. Defaulting to admin'
    GRAFANAPASSWORD=admin
fi
# optional logging to remote syslog server
if [ -z \${REMOTELOG+x} ];
then
    echo 'REMOTELOG is unset - see documentation how to configure this flavour with IP address of remote syslog server. Defaulting to null'
    REMOTELOG=\"null\"
fi
# sftpuser credentials
if [ -z \${SFTPUSER+x} ];
then
    echo 'SFTPUSER is unset - see documentation how to configure this flavour with sftp user and pass. Defaulting to username: certuser'
    SFTPUSER=\"certuser\"
fi
# sftpuser password
if [ -z \${SFTPPASS+x} ];
then
    echo 'SFTPPASS is unset - see documentation how to configure this flavour with sftp user and pass. Defaulting to password: c3rtp4ss'
    SFTPPASS=\"c3rtp4ss\"
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

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
    /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTSERVER:\$IP/key.pem
    /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTSERVER:\$IP/ca.pem
    /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTSERVER:\$IP/combinedca.pem
    cd ~
fi

# setup directories for vault usage
mkdir -p /mnt/templates
mkdir -p /mnt/certs/hash

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
 \\\"ca_file\\\": \\\"/mnt/certs/ca.pem\\\",
 \\\"cert_file\\\": \\\"/mnt/certs/cert.pem\\\",
 \\\"key_file\\\": \\\"/mnt/certs/key.pem\\\",
 \\\"log_file\\\": \\\"/var/log/consul/\\\",
 \\\"log_level\\\": \\\"WARN\\\",
 \\\"encrypt\\\": \$GOSSIPKEY,
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
}\" > /usr/local/etc/consul.d/agent.json

# set owner and perms on agent.json
chown consul:wheel /usr/local/etc/consul.d/agent.json
chmod 640 /usr/local/etc/consul.d/agent.json

# enable consul
sysrc consul_enable=\"YES\"

# set load parameter for consul config
sysrc consul_args=\"-config-file=/usr/local/etc/consul.d/agent.json\"
#sysrc consul_datadir=\"/var/db/consul\"

# Workaround for bug in rc.d/consul script:
sysrc consul_group=\"wheel\"

# setup consul logs, might be redundant if not specified in agent.json above
mkdir -p /var/log/consul
touch /var/log/consul/consul.log
chown -R consul:wheel /var/log/consul

# add the consul user to the wheel group, this seems to be required for
# consul to start on this instance. May need to figure out why.
# I'm not entirely sure this is the correct way to do it
/usr/sbin/pw usermod consul -G wheel

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
}\" > /usr/local/etc/vault.hcl

# setup template files for certificates
# this is not currently in use because cron job does renewal and services restart
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
chown -R vault:wheel /mnt/certs
chown -R vault:wheel /mnt/templates

# setup rc.conf entries
# we do not set vault_user=vault because vault will not start
# we're not starting vault as a service
sysrc vault_enable=no
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
/usr/local/bin/vault unwrap -address=https://\$VAULTSERVER:8200 -client-cert=/tmp/tmpcerts/cert.pem -client-key=/tmp/tmpcerts/key.pem -ca-cert=/mnt/certs/intermediate.cert.pem -format=json \$VAULTTOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/unwrapped.token
sleep 1
if [ -s /root/unwrapped.token ]; then
    echo \"Token unwrapped\"
    THIS_TOKEN=\$(/bin/cat /root/unwrapped.token)
    echo \"Logging in to vault leader to authenticate\"
    echo \"\$THIS_TOKEN\" | /usr/local/bin/vault login -address=https://\$VAULTSERVER:8200 -client-cert=/tmp/tmpcerts/cert.pem -client-key=/tmp/tmpcerts/key.pem -ca-cert=/mnt/certs/intermediate.cert.pem -method=token -field=token token=- > /root/login.token
    sleep 5
fi


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
    /usr/local/bin/curl --silent --cacert /tmp/tmpcerts/combinedca.pem --cert /tmp/tmpcerts/cert.pem --key /tmp/tmpcerts/key.pem --header \"X-Vault-Token: \$HEADER\" --request POST --data @/mnt/templates/payload.json https://\$VAULTSERVER:8200/v1/pki_int/issue/\$DATACENTER > /mnt/certs/vaultissue.json

    # extract the required certificates to individual files
    /usr/local/bin/jq -r '.data.certificate' /mnt/certs/vaultissue.json > /mnt/certs/cert.pem
    # append the ca cert to the cert
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json >> /mnt/certs/cert.pem
    /usr/local/bin/jq -r '.data.private_key' /mnt/certs/vaultissue.json > /mnt/certs/key.pem
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json > /mnt/certs/ca.pem
    cd /mnt/certs
    # concat the root CA and intermediary CA into combined file
    cat /mnt/certs/CA_cert.pem /mnt/certs/ca.pem > /mnt/certs/combinedca.pem
    # steps here to hash ca, required for syslog-ng
    ln -s ca.pem hash/\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/ca.pem).0
    ln -s combinedca.pem hash/\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/combinedca.pem).0
    cd /root
    # set permissions on /mnt/certs for vault
    chown -R vault:wheel /mnt/certs

    # validate the certificates
    echo \"Validating client certificate\"
    if [ -s /mnt/certs/combinedca.pem ] && [ -s /mnt/certs/cert.pem ]; then
        /usr/bin/openssl verify -CAfile /mnt/certs/combinedca.pem /mnt/certs/cert.pem
    fi

    # start consul agent
    /usr/local/etc/rc.d/consul start

    # setup certificate rotation script
    echo \"Setting up certificate rotation script\"
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
if [ -s /root/login.token ]; then
    LOGINTOKEN=\\\$(/bin/cat /root/login.token)
    HEADER=\\\$(echo \\\"X-Vault-Token: \\\"\\\$LOGINTOKEN)
    /usr/local/bin/curl --silent --cacert /mnt/certs/combinedca.pem --cert /mnt/certs/cert.pem --key /mnt/certs/key.pem --header \\\"\\\$HEADER\\\" --request POST --data @/mnt/templates/payload.json https://\$VAULTSERVER:8200/v1/pki_int/issue/\$DATACENTER > /mnt/certs/vaultissue.json
    # extract the required certificates to individual files
    /usr/local/bin/jq -r '.data.certificate' /mnt/certs/vaultissue.json > /mnt/certs/cert.pem
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json >> /mnt/certs/cert.pem
    /usr/local/bin/jq -r '.data.private_key' /mnt/certs/vaultissue.json > /mnt/certs/key.pem
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json > /mnt/certs/ca.pem
    cd /mnt/certs
    # concat the root CA and intermediary CA into combined file
    cat CA_cert.pem ca.pem > combinedca.pem
    # steps here to hash ca
    ln -s ca.pem hash\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/ca.pem).0
    ln -s combinedca.pem hash\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/combinedca.pem).0
    cd /root
    # set permissions on /mnt/certs for vault
    chown -R vault:wheel /mnt/certs
    # restart services
    /bin/pkill -HUP nomad
    /usr/local/etc/rc.d/consul restart
    /usr/local/etc/rc.d/syslog-ng restart
    /usr/local/etc/rc.d/grafana restart
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
else
    echo \"ERROR: There was a problem logging into vault and no certificates were retrieved. Vault not started.\"
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


## start node_exporter config
# node exporter needs tls setup
echo \"tls_server_config:
  cert_file: /mnt/certs/cert.pem
  key_file: /mnt/certs/key.pem
\" > /usr/local/etc/node-exporter.yml

# enable node_exporter service
sysrc node_exporter_enable=\"YES\"
sysrc node_exporter_args=\"--web.config=/usr/local/etc/node-exporter.yml\"
## end node_exporter config

## start grafana config
# we're mounting in a blank-or-filled ZFS dataset from root system at
# zroot/prometheusdata to /mnt

# if /mnt/grafana is empty, copy in /var/db/grafana

if [ ! -d /mnt/grafana ]; then
    # if empty we need to copy in the directory structure from install
    cp -a /var/db/grafana /mnt

    # make sure permissions are good for /mnt/grafana
    chown -R grafana:grafana /mnt/grafana

    # overwrite the rc file with a fixed one as per
    # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255676
    if [ -f /root/grafana.rc ]; then
        echo "replacing grafana rc file with freebsd-fixed one"
        cp -f /root/grafana.rc /usr/local/etc/rc.d/grafana
        chmod 755 /usr/local/etc/rc.d/grafana
        # this seems to be required, grafana still crashes without it
        chmod 755 /root
    else
        echo \"ERROR - no /root/grafana.rc file\"
    fi

    # copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    if [ -f /root/datasources.yml ]; then
        /usr/bin/sed -i .orig \"s/MYPROMHOST/\$PROMSOURCE/g\" /root/datasources.yml
        /usr/bin/sed -i .orig \"s/MYLOKIHOST/\$LOKISOURCE/g\" /root/datasources.yml
        /usr/bin/sed -i .orig \"s/MYINFLUXHOST/\$INFLUXDBSOURCE/g\" /root/datasources.yml
        /usr/bin/sed -i .orig \"s/INFLUXDATABASE/\$INFLUXDBSOURCE/g\" /root/datasources.yml
        cp -f /root/datasources.yml /mnt/grafana/provisioning/datasources/datasources.yml
        chown grafana:grafana /mnt/grafana/provisioning/datasources/datasources.yml
    else
        echo \"ERROR - NO DATASOURCE CONFIG FILE FOUND\"
    fi

    # copy in the dashboard.yml file to /mnt/grafana/provisioning/dashboards
    if [ -f /root/dashboard.yml ]; then
        cp -f /root/dashboard.yml /mnt/grafana/provisioning/dashboards/default.yml
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/default.yml
    else
        echo \"ERROR - NO DASHBOARD DEFAULT CONFIG FILE FOUND\"
    fi
    # include the relevant .json for actual dashboard as follows
    # using https://raw.githubusercontent.com/rfrail3/grafana-dashboards/master/prometheus/node-exporter-freebsd.json
    # as source dashboard json for demo purposes
    if [ -f /root/home.json ]; then
        cp -f /root/home.json /mnt/grafana/provisioning/dashboards/home.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/home.json
    else
        echo \"ERROR - could not find home.json to copy in as default dashboard\"
    fi
    if [ -f /root/homelogs.json ]; then
        cp -f /root/homelogs.json /mnt/grafana/provisioning/dashboards/homelogs.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/homelogs.json
    else
        echo \"Error - could not find home.json to copy in as default dashboard\"
    fi
    if [ -f /root/vault.json ]; then
        cp -f /root/vault.json /mnt/grafana/provisioning/dashboards/vault.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/vault.json
    else
        echo \"Error - could not find vault.json to copy in as additional dashboard\"
    fi
    if [ -f /root/nomadcluster.json ]; then
        cp -f /root/nomadcluster.json /mnt/grafana/provisioning/dashboards/nomadcluster.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/nomadcluster.json
    else
        echo \"Error - could not find nomadcluster.json to copy in as additional dashboard\"
    fi
    if [ -f /root/nomadjobs.json ]; then
        cp -f /root/nomadjobs.json /mnt/grafana/provisioning/dashboards/nomadjobs.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/nomadjobs.json
    else
        echo \"Error - could not find nomadjobs.json to copy in as additional dashboard\"
    fi
    if [ -f /root/consulcluster.json ]; then
        cp -f /root/consulcluster.json /mnt/grafana/provisioning/dashboards/consulcluster.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/consulcluster.json
    else
        echo \"Error - could not find consulcluster.json to copy in as additional dashboard\"
    fi
    if [ -f /root/postgres.json ]; then
        cp -f /root/postgres.json /mnt/grafana/provisioning/dashboards/postgres.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/postgres.json
    else
        echo \"Error - could not find postgres.json to copy in as additional dashboard\"
    fi
else
    # if /mnt/grafana exists then don't copy in /var/db/grafana
    # make sure permissions are good for /mnt/grafana
    chown -R grafana:grafana /mnt/grafana

    # overwrite the rc file with a fixed one as per
    # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255676
    if [ -f /root/grafana.rc ]; then
        echo "replacing grafana rc file with freebsd-fixed one"
        cp -f /root/grafana.rc /usr/local/etc/rc.d/grafana
        chmod 755 /usr/local/etc/rc.d/grafana
        # this seems to be required, grafana still crashes without it
        chmod 755 /root
    else
        echo \"ERROR - no /root/grafana.rc file\"
    fi

    # copy in the datasource.yml file to /mnt/grafana/provisioning/datasources
    if [ -f /root/datasources.yml ]; then
        /usr/bin/sed -i .orig \"s/MYPROMHOST/\$PROMSOURCE/g\" /root/datasources.yml
        /usr/bin/sed -i .orig \"s/MYLOKIHOST/\$LOKISOURCE/g\" /root/datasources.yml
        /usr/bin/sed -i .orig \"s/MYINFLUXHOST/\$INFLUXDBSOURCE/g\" /root/datasources.yml
        /usr/bin/sed -i .orig \"s/INFLUXDATABASE/\$INFLUXDBSOURCE/g\" /root/datasources.yml
        cp -f /root/datasources.yml /mnt/grafana/provisioning/datasources/datasources.yml
        chown grafana:grafana /mnt/grafana/provisioning/datasources/datasources.yml
    else
        echo \"ERROR - NO DATASOURCE CONFIG FILE FOUND\"
    fi

    # copy in the dashboard.yml file to /mnt/grafana/provisioning/dashboards
    if [ -f /root/dashboard.yml ]; then
        cp -f /root/dashboard.yml /mnt/grafana/provisioning/dashboards/default.yml
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/default.yml
    else
        echo \"ERROR - NO DASHBOARD DEFAULT CONFIG FILE FOUND\"
    fi
    # include the relevant .json for actual dashboard as follows
    # home.json is generated from
    # 1. https://raw.githubusercontent.com/rfrail3/grafana-dashboards/master/prometheus/node-exporter-freebsd.json
    # 2. fixed with header bits from https://grafana.com/api/dashboards/13978/revisions/1/download
    # as source dashboard
    if [ -f /root/home.json ]; then
        cp -f /root/home.json /mnt/grafana/provisioning/dashboards/home.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/home.json
    else
        echo \"ERROR - could not find home.json to copy in as default dashboard\"
    fi
    if [ -f /root/homelogs.json ]; then
        cp -f /root/homelogs.json /mnt/grafana/provisioning/dashboards/homelogs.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/homelogs.json
    else
        echo \"ERROR - could not find home.json to copy in as default dashboard\"
    fi
    if [ -f /root/vault.json ]; then
        cp -f /root/vault.json /mnt/grafana/provisioning/dashboards/vault.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/vault.json
    else
        echo \"Error - could not find vault.json to copy in as additional dashboard\"
    fi
    if [ -f /root/nomadcluster.json ]; then
        cp -f /root/nomadcluster.json /mnt/grafana/provisioning/dashboards/nomadcluster.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/nomadcluster.json
    else
        echo \"Error - could not find nomadcluster.json to copy in as additional dashboard\"
    fi
    if [ -f /root/nomadjobs.json ]; then
        cp -f /root/nomadjobs.json /mnt/grafana/provisioning/dashboards/nomadjobs.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/nomadjobs.json
    else
        echo \"Error - could not find nomadjobs.json to copy in as additional dashboard\"
    fi
    if [ -f /root/consulcluster.json ]; then
        cp -f /root/consulcluster.json /mnt/grafana/provisioning/dashboards/consulcluster.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/consulcluster.json
    else
        echo \"Error - could not find consulcluster.json to copy in as additional dashboard\"
    fi
    if [ -f /root/postgres.json ]; then
        cp -f /root/postgres.json /mnt/grafana/provisioning/dashboards/postgres.json
        chown grafana:grafana /mnt/grafana/provisioning/dashboards/postgres.json
    else
        echo \"Error - could not find postgres.json to copy in as additional dashboard\"
    fi
fi

# local edits for grafana.conf here
# the mount path for some options is set to /mnt/grafana/...
if [ -f /root/grafana.conf ]; then
    /usr/bin/sed -i .orig \"s/MYGRAFANAUSER/\$GRAFANAUSER/g\" /root/grafana.conf
    /usr/bin/sed -i .orig \"s/MYGRAFANAPASSWORD/\$GRAFANAPASSWORD/g\" /root/grafana.conf
    cp -f /root/grafana.conf /usr/local/etc/grafana.conf
    # enable grafana service
    sysrc grafana_enable=\"YES\"
    sysrc grafana_config=\"/usr/local/etc/grafana.conf\"
    sysrc grafana_user=\"grafana\"
    sysrc grafana_group=\"grafana\"
    sysrc grafana_syslog_output_enable=\"YES\"
    # start grafana
    /usr/local/etc/rc.d/grafana start
else
    echo \"ERROR - there is no /root/grafana.conf file. Grafana not started\"
fi

## end grafana config

#
# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# start node_exporter
/usr/local/etc/rc.d/node_exporter start

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
