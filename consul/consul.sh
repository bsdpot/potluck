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

step "Enable consul startup"
#sysrc consul_enable="YES"
service consul enable

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

step "Install package consul"
pkg install -y consul

step "Install package sudo"
pkg install -y sudo

step "Install package node_exporter"
pkg install -y node_exporter

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
/usr/local/etc/rc.d/consul stop  || true

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
if [ -z \${NODENAME+x} ];
then
    echo 'NODENAME is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${IP+x} ];
then
    echo 'IP is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${PEERS+x} ];
then
    echo 'PEERS is unset - see documentation how to configure this flavour, defaulting to null'
    PEERS='\"\"'
fi
if [ -z \${BOOTSTRAP+x} ];
then
    echo 'BOOTSTRAP is unset - see documentation how to configure this flavour, defaulting to 1'
    BOOTSTRAP=1
fi
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen
# you must generate this key on a live consul server
if [ -z \${GOSSIPKEY+x} ];
then
    echo 'GOSSIPKEY is unset - see documentation how to configure this flavour, defaulting to preset encrypt key. Do not use this in production!'
    GOSSIPKEY='BY+vavBUSEmNzmxxS3k3bmVFn1giS4uEudc774nBhIw='
fi
# Remotelog is a remote syslog server, need to pass in IP
if [ -z \${REMOTELOG+x} ];
then
    echo 'REMOTELOG is unset - see documentation how to configure this flavour'
    REMOTELOG='unset'
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# Create consul server config file, set the bootstrap_expect value to number
# of servers in the cluster, 3 or 5
mkdir -p /usr/local/etc/consul.d
chown consul /usr/local/etc/consul.d
chmod 750 /usr/local/etc/consul.d

# There are two different configs whether consul is a single server or 3 or 5
# The BOOTSTRAP parameter MUST be set, and the PEERS variable MUST be in the
# correct format

case \$BOOTSTRAP in

  1)
    echo \"{
     \\\"bind_addr\\\": \\\"0.0.0.0\\\",
     \\\"client_addr\\\": \\\"0.0.0.0\\\",
     \\\"datacenter\\\": \\\"\$DATACENTER\\\",
     \\\"data_dir\\\":  \\\"/var/db/consul\\\",
     \\\"dns_config\\\": {
       \\\"a_record_limit\\\": 3,
       \\\"enable_truncate\\\": true
     },
     \\\"verify_incoming\\\": false,
     \\\"verify_outgoing\\\": false,
     \\\"verify_server_hostname\\\": false,
     \\\"verify_incoming_rpc\\\": false,
     \\\"enable_syslog\\\": true,
     \\\"leave_on_terminate\\\": true,
     \\\"log_level\\\": \\\"WARN\\\",
     \\\"node_name\\\": \\\"\$NODENAME\\\",
     \\\"translate_wan_addrs\\\": true,
     \\\"ui\\\": true,
     \\\"server\\\": true,
     \\\"encrypt\\\": \\\"\$GOSSIPKEY\\\",
     \\\"bootstrap_expect\\\": \$BOOTSTRAP,
     \\\"telemetry\\\": {
       \\\"prometheus_retention_time\\\": \\\"24h\\\"
     },
     \\\"service\\\": {
      \\\"address\\\": \\\"\$IP\\\",
      \\\"name\\\": \\\"node-exporter\\\",
      \\\"tags\\\": [\\\"_app=consul\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\", \\\"_datacenter=\$DATACENTER\\\"],
      \\\"port\\\": 9100
     }
    }\" > /usr/local/etc/consul.d/agent.json

    echo \"consul_args=\\\"-advertise \$IP\\\"\" >> /etc/rc.conf
    ;;

  3|5)
    echo \"{
     \\\"bind_addr\\\": \\\"0.0.0.0\\\",
     \\\"client_addr\\\": \\\"0.0.0.0\\\",
     \\\"datacenter\\\": \\\"\$DATACENTER\\\",
     \\\"data_dir\\\":  \\\"/var/db/consul\\\",
     \\\"dns_config\\\": {
       \\\"a_record_limit\\\": 3,
       \\\"enable_truncate\\\": true
     },
     \\\"verify_incoming\\\": false,
     \\\"verify_outgoing\\\": false,
     \\\"verify_server_hostname\\\": false,
     \\\"verify_incoming_rpc\\\": false,
     \\\"enable_syslog\\\": true,
     \\\"leave_on_terminate\\\": true,
     \\\"log_level\\\": \\\"WARN\\\",
     \\\"node_name\\\": \\\"\$NODENAME\\\",
     \\\"translate_wan_addrs\\\": true,
     \\\"ui\\\": true,
     \\\"server\\\": true,
     \\\"encrypt\\\": \\\"\$GOSSIPKEY\\\",
     \\\"bootstrap_expect\\\": \$BOOTSTRAP,
     \\\"rejoin_after_leave\\\": true,
     \\\"start_join\\\": [\\\"\$IP\\\", \$PEERS],
     \\\"telemetry\\\": {
       \\\"prometheus_retention_time\\\": \\\"24h\\\"
     },
     \\\"service\\\": {
      \\\"address\\\": \\\"\$IP\\\",
      \\\"name\\\": \\\"node-exporter\\\",
      \\\"tags\\\": [\\\"_app=consul\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\", \\\"_datacenter=\$DATACENTER\\\"],
      \\\"port\\\": 9100
   }
  }\" > /usr/local/etc/consul.d/agent.json

    echo \"consul_args=\\\"-advertise \$IP\\\"\" >> /etc/rc.conf
    ;;

  *)
    echo \"there is a problem with the BOOTSTRAP VARIABLE\"
    exit 1
    ;;

esac

## remote syslogs
if [ \"${REMOTELOG}\" == \"unset\" ]; then
    echo \"Remotelog is not set. Try passing in an IP address of a syslog server\"
else
    mkdir -p /usr/local/etc/syslog.d
    echo \"*.*     @${REMOTELOG}\" > /usr/local/etc/syslog.d/logtoremote.conf
    service syslogd restart
fi

## end consul setup
if ! id -u \\\"nodeexport\\\" >/dev/null 2>&1; then
  /usr/sbin/pw useradd -n nodeexport -c 'nodeexporter user' -m -s /usr/bin/nologin -h -
fi

# enable node_exporter service
#sysrc node_exporter_enable=\"YES\"
service node_exporter enable
sysrc node_exporter_args=\"--log.level=warn\"
sysrc node_exporter_user=nodeexport
sysrc node_exporter_group=nodeexport

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# start consul
#/usr/local/etc/rc.d/consul start
service consul start

# start node_exporter
#/usr/local/etc/rc.d/node_exporter start
service node_exporter start

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
