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

step "Enable SSH"
sysrc sshd_enable="YES"

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

# we need consul for consul agent
step "Install package consul"
pkg install -y consul

step "Install package sudo"
pkg install -y sudo

step "Install package node_exporter"
pkg install -y node_exporter

step "Install package jq"
pkg install -y jq

step "Install package jo"
pkg install -y jo

step "Install package curl"
pkg install -y curl

step "Install package openssl"
pkg install -y openssl

step "Install package syslog-ng"
pkg install -y syslog-ng

step "Install package py38-salt"
pkg install -y py38-salt

step "Install package git-lite"
pkg install -y git-lite

step "Install package go"
pkg install -y go

step "Install package gmake"
pkg install -y gmake

step "Install package curl"
pkg install -y curl

step "Install package nano"
pkg install -y nano

step "Install package tmux"
pkg install -y tmux

step "Clean package installation"
pkg autoremove -y
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
# datacenter check
if [ -z \${DATACENTER+x} ]; then
    echo 'DATACENTER is unset - see documentation to configure this flavour with the datacenter name.'
    exit 1
fi
# nodename check
if [ -z \${NODENAME+x} ];
then
    echo 'NODENAME is unset - see documentation to configure this flavour with a name for this node.'
    exit 1
fi
# IP address check
if [ -z \${IP+x} ]; then
    echo 'IP is unset - see documentation to configure this flavour for an IP address.'
    exit 1
fi
# enable consul check
if [ -z \${ENABLECONSUL+x} ];
then
    echo 'ENABLECONSUL is unset - please pass in 1 to enable consul or 0 to disable consul setup. Defaulting to 0. If enabled you must pass in a list of consul servers.'
    ENABLECONSUL=0
fi
# consul check
if [ -z \${CONSULSERVERS+x} ] && [ \$ENABLECONSUL != 0 ];
then
    echo 'CONSULSERVERS is unset - please pass in one or more correctly-quoted, comma-separated addresses for consul peer IPs. Refer to documentation.'
    exit 1
fi
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen for the consul flavour.
# Re-used for nomad, which is usually 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the one from the consul flavour
if [ -z \${GOSSIPKEY+x} ];
then
    echo 'GOSSIPKEY is unset - see documentation how to configure this flavour, defaulting to preset encrypt key. Do not use this in production!'
    GOSSIPKEY='BY+vavBUSEmNzmxxS3k3bmVFn1giS4uEudc774nBhIw='
fi
# SSHUSER credentials check
if [ -z \${SSHUSER+x} ];
then
    echo 'SSHUSER is unset - please provide a username to use for the SSH user.'
    exit 1
fi
# SSHPORT credentials check
if [ -z \${SSHPORT+x} ];
then
    echo 'SSHPORT is unset - please provide a port number for SSH. Default for this pot image is 7777.'
    SSHPORT=7777
fi
# PKIPATH check
if [ -z \${PKIPATH+x} ];
then
    echo 'PKIPATH is unset - please provide a path for mounted in persistent storage to use for salt PKI files.'
    exit 1
fi
# STATEPATH check
if [ -z \${STATEPATH+x} ];
then
    echo 'STATEPATH is unset - please provide a path for mounted in persistent storage to use for salt state files.'
    exit 1
fi
# PILLARPATH check
if [ -z \${PILLARPATH+x} ];
then
    echo 'PILLARPATH is unset - please provide a path for mounted in persistent storage to use for salt pillar files.'
    exit 1
fi
# optional logging to remote syslog server check
if [ -z \${REMOTELOG+x} ];
then
    echo 'REMOTELOG is unset - please provide the IP address of a loki server, or set a null value.'
    REMOTELOG=\"null\"
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# setup directories for salt usage
mkdir -p /mnt/salt/pki/master
mkdir -p /mnt/salt/state
mkdir -p /mnt/salt/pillar
mkdir -p /mnt/home

## start ssh setup

# begin SSHUSER configuration
echo \"Setting up custom ssh parameters\"

echo \"Port \$SSHPORT
PubkeyAuthentication yes
AuthorizedKeysFile       .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
StrictModes no
UseDNS no
Banner none
#LogLevel DEBUG
AllowAgentForwarding yes
PermitTTY yes
#AllowUsers \$SSHUSER
#Match User \$SSHUSER
#  ChrootDirectory /dir-name
#  X11Forwarding no
#  AllowTcpForwarding no
#  ForceCommand internal-sftp
\" >> /etc/ssh/sshd_config

# setup host keys
echo \"Manually setting up host keys\"
cd /etc/ssh
/usr/bin/ssh-keygen -A
cd /

# setup a user
/usr/sbin/pw useradd -n \$SSHUSER -c 'ssh user' -d /mnt/home/\$SSHUSER -G wheel -m -s /bin/sh -h -

# setup user ssh key to be exported for use elsewhere
echo \"Setting up \$SSHUSER ssh keys\"
mkdir -p /mnt/home/\$SSHUSER/.ssh
/usr/bin/ssh-keygen -q -N '' -f /mnt/home/\$SSHUSER/.ssh/id_rsa -t rsa
chmod 700 /mnt/home/\$SSHUSER/.ssh
cat /mnt/home/\$SSHUSER/.ssh/id_rsa.pub > /mnt/home/\$SSHUSER/.ssh/authorized_keys
chmod 700 /mnt/home/\$SSHUSER/.ssh
chmod 600 /mnt/home/\$SSHUSER/.ssh/id_rsa
chmod 644 /mnt/home/\$SSHUSER/.ssh/authorized_keys
chown \$SSHUSER:wheel /mnt/home/\$SSHUSER/.ssh

# restart ssh
echo \"Restarting ssh\"
/etc/rc.d/sshd restart

## end ssh setup

## start remote logging setup

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
        service syslog-ng start
        echo \"syslog-ng setup complete\"
    else
        echo \"/root/syslog-ng.conf is missing?\"
    fi
else
    echo \"REMOTELOG parameter is not set to an IP address. syslog-ng won't operate.\"
fi

## end remote logging setup

## start consul setup

if [ \$ENABLECONSUL = 1 ]; then
    # make consul configuration directory and set permissions
    mkdir -p /usr/local/etc/consul.d
    chown consul /usr/local/etc/consul.d
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
\\\"verify_incoming\\\": false,
\\\"verify_outgoing\\\": false,
\\\"verify_server_hostname\\\": false,
\\\"verify_incoming_rpc\\\": false,
\\\"log_file\\\": \\\"/var/log/consul/\\\",
\\\"log_level\\\": \\\"WARN\\\",
\\\"encrypt\\\": \\\"\$GOSSIPKEY\\\",
\\\"start_join\\\": [ \$CONSULSERVERS ],
\\\"service\\\": {
  \\\"name\\\": \\\"node-exporter\\\",
  \\\"tags\\\": [\\\"_app=saltstack\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\"],
  \\\"port\\\": 9100
}
}\" | (umask 177; cat > /usr/local/etc/consul.d/agent.json)

    # set owner and perms on _directory_ /usr/local/etc/consul.d with agent.json
    chown -R consul:wheel /usr/local/etc/consul.d/
    #chmod 640 /usr/local/etc/consul.d/agent.json

    # enable consul
    service consul enable

    # set load parameter for consul config
    sysrc consul_args=\"-config-file=/usr/local/etc/consul.d/agent.json\"
    # not needed
    #sysrc consul_datadir=\"/var/db/consul\"
    #sysrc consul_group=\"wheel\"

    # setup consul logs, might be redundant if not specified in agent.json above
    mkdir -p /var/log/consul
    touch /var/log/consul/consul.log
    chown -R consul:wheel /var/log/consul

    # add the consul user to the wheel group, this is old behaviour and may be fixed
    /usr/sbin/pw usermod consul -G wheel

    # start consul agent
    service consul start

    ## end consul setup

    ## start node exporter setup

    ## DISABLED as not using TLS
    ## node exporter needs tls setup
    ##echo \"tls_server_config:
    ##  cert_file: /mnt/certs/cert.pem
    ##  key_file: /mnt/certs/key.pem
    ##\" > /usr/local/etc/node-exporter.yml

    ## replacement to above disabled bit with empty file
    touch /usr/local/etc/node-exporter.yml

    # add node_exporter user
    /usr/sbin/pw useradd -n nodeexport -c 'nodeexporter user' -m -s /usr/bin/nologin -h -

    # enable node_exporter service
    service node_exporter enable
    sysrc node_exporter_args=\"--web.config=/usr/local/etc/node-exporter.yml\"
    sysrc node_exporter_user=nodeexport
    sysrc node_exporter_group=nodeexport

    # start node_exporter
    service node_exporter start

    ## end node exporter setup
else
    echo \"Consul is not being enabled.\"
fi
## end consul optional

## start saltstack setup

# check if copied in file exists, and make path changes from variables
if [ -f /root/master.cfg ]; then
    # set the PKIPATH placeholder to the passed in mounted path for persistent storage
    /usr/bin/sed -i .orig 's|PKIPATH|'\$PKIPATH'|g' /root/master.cfg
    # set the STATEPATH placeholder to the passed in mounted path for persistent storage
    /usr/bin/sed -i .orig 's|STATEPATH|'\$STATEPATH'|g' /root/master.cfg
    # set the PILLARPATH placeholder to the passed in mounted path for persistent storage
    /usr/bin/sed -i .orig 's|PILLARPATH|'\$PILLARPATH'|g' /root/master.cfg
    # copy to /usr/local/etc/salt
    cp -f /root/master.cfg /usr/local/etc/salt/master
fi

# check for copied in master.pem and master.pub and copy to PKIPATH location, overwriting any keys there
if [ -f /root/master.pem ]; then
    # backup existing key and set destination to readwrite
    if [ -f \$PKIPATH/master.pem ]; then
        cp -f \$PKIPATH/master.pem \$PKIPATH/master.pem.old
        chmod 400 \$PKIPATH/master.pem.old
        chmod 600 \$PKIPATH/master.pem
    fi
    # copy key over
    cp -f /root/master.pem \$PKIPATH/master.pem
    # set destination to read only
    chmod 400 \$PKIPATH/master.pem
else
    echo \"There is no master.pem file to copy into salt\"
fi

# copy over pubkey
if [ -f /root/master.pub ]; then
    if [ -f \$PKIPATH/master.pub ]; then
        cp -f \$PKIPATH/master.pub \$PKIPATH/master.pub.old
    fi
    cp -f /root/master.pub \$PKIPATH/master.pub
    chmod 644 \$PKIPATH/master.pub
else
    echo \"There is no master.pub file to copy into salt\"
fi
# make sure ownership is correct
chown root:wheel \$PKIPATH

# enable salt master
service salt_master enable

# start salt master service
service salt_master start

## end saltstack setup

## notice
echo \"================================================================\"
echo \" Copy out /mnt/home/\$SSHUSER/.ssh/id_rsa to use as SSH private \"
echo \"            key for remote access without password.             \"
echo \"================================================================\"


# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

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
