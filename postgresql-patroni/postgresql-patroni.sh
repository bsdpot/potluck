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
service sendmail disable

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

step "Update package repository"
pkg update -f

step "Install package sudo"
pkg install -y sudo

step "Install package openssl"
pkg install -y openssl

step "Install package vault"
pkg install -y vault

step "Install package consul"
pkg install -y consul

step "Install package node_exporter"
pkg install -y node_exporter

step "Install package postgresql-client"
pkg install -y postgresql13-client

step "Install package postgresql-server"
pkg install -y postgresql13-server

step "Install package python37"
pkg install -y python37

step "Install package python3-pip"
pkg install -y py37-pip

step "Install package python-consul2"
pkg install -y py37-python-consul2

step "Install package psycopg2"
pkg install -y py37-psycopg2
#
# pip MUST ONLY be used:
# * With the --user flag, OR
# * To install or manage Python packages in virtual environments
# using -prefix here to force install in /usr/local/bin

step "Install pip package patroni"
pip install patroni --prefix="/usr/local"
#
## WARNING: The scripts patroni, patroni_aws, patroni_raft_controller,
## patroni_wale_restore and patronictl are installed in
## '--prefix=/usr/local/bin' which is not on PATH.
## Consider adding this directory to PATH or, if you prefer to suppress
## this warning, use --no-warn-script-location.

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
#

# stop consul agent
/usr/local/etc/rc.d/consul stop || true

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
if [ -z \${DATACENTER+x} ];
then
    echo 'DATACENTER is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${CONSULSERVERS+x} ];
then
    echo 'CONSULSERVERS is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${NODENAME+x} ];
then
    echo 'The unique option NODENAME is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${MYIP+x} ];
then
    echo 'MYIP is unset - see documentation how to configure this flavour'
    MYIP=\"127.0.0.1\"
fi
if [ -z \${SERVICETAG+x} ];
then
    echo 'SERVICETAG is unset - see documentation how to configure this flavour'
    SERVICETAG=master
fi
if [ -z \${ADMPASS+x} ];
then
    echo 'ADMPASS is unset - see documentation how to configure this flavour'
    ADMPASS=admin
fi
if [ -z \${KEKPASS+x} ];
then
    echo 'KEKPASS is unset - see documentation how to configure this flavour'
    KEKPASS=kekpass
fi
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen for the consul flavour.
# Re-used for nomad, which is usually 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the one from the consul flavour
if [ -z \${GOSSIPKEY+x} ];
then
    echo 'GOSSIPKEY is unset - see documentation how to configure this flavour, defaulting to preset encrypt key. Do not use this in production!'
    GOSSIPKEY='\"BY+vavBUSEmNzmxxS3k3bmVFn1giS4uEudc774nBhIw=\"'
fi

# make consul configuration directory and set permissions
mkdir -p /usr/local/etc/consul.d
chmod 750 /usr/local/etc/consul.d

# Create the consul agent config file with imported variables
echo \"{
 \\\"advertise_addr\\\": \\\"\$MYIP\\\",
 \\\"datacenter\\\": \\\"\$DATACENTER\\\",
 \\\"node_name\\\": \\\"\$NODENAME\\\",
 \\\"data_dir\\\":  \\\"/var/db/consul\\\",
 \\\"dns_config\\\": {
  \\\"a_record_limit\\\": 3,
  \\\"enable_truncate\\\": true
 },
 \\\"log_file\\\": \\\"/var/log/consul/\\\",
 \\\"log_level\\\": \\\"WARN\\\",
 \\\"encrypt\\\": \$GOSSIPKEY,
 \\\"start_join\\\": [ \$CONSULSERVERS ],
 \\\"service\\\": {
  \\\"name\\\": \\\"node_exporter\\\",
  \\\"tags\\\": [\\\"_app=postgresql\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\"],
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

# enable node_exporter service
sysrc node_exporter_enable=\"YES\"

# set patroni variables in /root/patroni.yml before copy
if [ -f /root/patroni.yml ]; then
    # replace MYNAME with imported variable NODENAME which must be unique
    /usr/bin/sed -i .orig \"/MYNAME/s/MYNAME/\$NODENAME/g\" /root/patroni.yml

    # replace MYIP with imported variable MYIP
    /usr/bin/sed -i .orig \"/MYIP/s/MYIP/\$MYIP/g\" /root/patroni.yml

    # replace SERVICETAG with imported variable SERVICETAG
    /usr/bin/sed -i .orig \"/SERVICETAG/s/SERVICETAG/\$SERVICETAG/g\" /root/patroni.yml

    # replace CONSULIP with imported variable MYIP, as using local consul agent
    /usr/bin/sed -i .orig \"/CONSULIP/s/CONSULIP/\$MYIP/g\" /root/patroni.yml

    # replace ADMPASS with imported variable ADMPASS
    /usr/bin/sed -i .orig \"/ADMPASS/s/ADMPASS/\$ADMPASS/g\" /root/patroni.yml

    # replace KEKPASS with imported variable KEKPASS
    /usr/bin/sed -i .orig \"/KEKPASS/s/KEKPASS/\$KEKPASS/g\" /root/patroni.yml
fi

# create /usr/local/etc/patroni/
mkdir -p /usr/local/etc/patroni/

# copy the file to startup location
cp /root/patroni.yml /usr/local/etc/patroni/patroni.yml

# copy patroni startup script to /usr/local/etc/rc.d/
cp /root/patroni.rc /usr/local/etc/rc.d/patroni

# enable postgresql
sysrc postgresql_enable=\"YES\"

# enable patroni
sysrc patroni_enable=\"YES\"

# end postgresql

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# start consul agent
/usr/local/etc/rc.d/consul start

# start patroni, which should start postgresql
/usr/local/etc/rc.d/patroni start

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
