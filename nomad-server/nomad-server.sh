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

step "Install package nomad"
pkg install -y nomad

step "Install package sudo"
pkg install -y sudo

step "Install package syslog-ng"
pkg install -y syslog-ng

step "Install package node_exporter"
pkg install -y node_exporter

step "Create nomad jobs directory"
mkdir -p /root/nomadjobs

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
service consul onestop || true
service nomad onestop || true

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
if [ -z \${REGION+x} ];
then
    echo 'REGION is unset - setting default of global - see documentation how to configure this flavour'
    REGION=global
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
if [ -z \${CONSULSERVERS+x} ];
then
    echo 'CONSULSERVERS is unset - you must include at least one consul server IP'
    exit 1
fi
if [ -z \${BOOTSTRAP+x} ];
then
    echo 'BOOTSTRAP is unset - see documentation how to configure this flavour, defaulting to 1'
    BOOTSTRAP=1
fi
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen for the consul flavour.
# Re-used for nomad, which is usually 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the one from the consul flavour
if [ -z \${GOSSIPKEY+x} ];
then
    echo 'GOSSIPKEY is unset - see documentation how to configure this flavour, defaulting to preset encrypt key. Do not use this in production!'
    GOSSIPKEY='BY+vavBUSEmNzmxxS3k3bmVFn1giS4uEudc774nBhIw='
fi
# NOMADKEY is a 32 byte, Base64 encoded key generated with 'openssl rand -base64 32'.
# 'nomad operator keygen' usually produces a 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the GOSSIPKEY variable consul but you can set own different key for nomad
if [ -z \${NOMADKEY+x} ];
then
    echo 'NOMADKEY is unset - see documentation how to configure this flavour, defaulting to preset encrypt key. Do not use this in production!'
    NOMADKEY=\$GOSSIPKEY
fi
# Importjobs flag to enable automatic job importing
if [ -z \${IMPORTJOBS+x} ];
then
    echo 'IMPORTJOBS is unset - see documentation how to configure this flavour'
    IMPORTJOBS=0
fi
# Remotelog is a remote syslog server, need to pass in IP
if [ -z \${REMOTELOG+x} ];
then
    echo 'REMOTELOG is unset - see documentation how to configure this flavour'
    REMOTELOG=0
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# start consul #

# Create consul client config file, set the bootstrap_expect value to number
# of servers in the cluster, 1, 3 or 5

# first create configuration directory

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
 \\\"verify_incoming\\\": false,
 \\\"verify_outgoing\\\": false,
 \\\"verify_server_hostname\\\": false,
 \\\"verify_incoming_rpc\\\": false,
 \\\"log_file\\\": \\\"/var/log/consul/\\\",
 \\\"log_level\\\": \\\"WARN\\\",
 \\\"encrypt\\\": \\\"\$GOSSIPKEY\\\",
 \\\"start_join\\\": [ \$CONSULSERVERS ],
 \\\"telemetry\\\": {
   \\\"prometheus_retention_time\\\": \\\"24h\\\"
 },
 \\\"service\\\": {
   \\\"address\\\": \\\"\$IP\\\",
   \\\"name\\\": \\\"node-exporter\\\",
   \\\"tags\\\": [\\\"_app=nomad-server\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\", \\\"_datacenter=\$DATACENTER\\\"],
   \\\"port\\\": 9100
 }
}\" > /usr/local/etc/consul.d/agent.json

# set owner and perms on agent.json
chown -R consul:wheel /usr/local/etc/consul.d
#chmod 640 /usr/local/etc/consul.d/agent.json
chmod 750 /usr/local/etc/consul.d

# enable consul
#sysrc consul_enable=\"YES\"
service consul enable

# set load parameter for consul config
sysrc consul_args=\"-config-file=/usr/local/etc/consul.d/agent.json\"
#sysrc consul_datadir=\"/var/db/consul\"

# Workaround for bug in rc.d/consul script:
#sysrc consul_group=\"wheel\"

# setup consul logs, might be redundant if not specified in agent.json above
mkdir -p /var/log/consul
touch /var/log/consul/consul.log
chown -R consul:wheel /var/log/consul

# add the consul user to the wheel group, this seems to be required for
# consul to start on this instance. May need to figure out why.
# I'm not entirely sure this is the correct way to do it
/usr/sbin/pw usermod consul -G wheel

# end consul #

# add node_exporter user
if ! id -u \"nodeexport\" >/dev/null 2>&1; then
  /usr/sbin/pw useradd -n nodeexport -c 'nodeexporter user' -m -s /usr/bin/nologin -h -
fi

# enable node_exporter service
#sysrc node_exporter_enable=\"YES\"
service node_exporter enable
sysrc node_exporter_args=\"--log.level=warn\"
sysrc node_exporter_user=nodeexport
sysrc node_exporter_group=nodeexport

# start nomad #

# fix /var/tmp/nomad issue
if [ -d /var/tmp/nomad ]; then
    mv -f /var/tmp/nomad /var/tmp/oldnomad
fi

# Create nomad server config file
echo \"
bind_addr = \\\"\$IP\\\"
plugin_dir = \\\"/usr/local/libexec/nomad/plugins\\\"
datacenter = \\\"\$DATACENTER\\\"
region = \\\"\$REGION\\\"
advertise {
  # This should be the IP of THIS MACHINE and must be routable by every node
  # in your cluster
  http = \\\"\$IP:4646\\\"
}
server {
  enabled = true
  # set this to 3 or 5 for cluster setup
  bootstrap_expect = \\\"\$BOOTSTRAP\\\"
  # Encrypt gossip communication
  encrypt = \\\"\$NOMADKEY\\\"
}
consul {
  # The address to the local Consul agent.
  address = \\\"\$IP:8500\\\"
  # The service name to register the server and client with Consul.
  server_service_name = \\\"\$DATACENTER-server\\\"
  # Enables automatically registering the services.
  auto_advertise = true
  # Enabling the server and client to bootstrap using Consul.
  server_auto_join = true
}
telemetry {
  publish_allocation_metrics = true
  publish_node_metrics = true
  prometheus_metrics = true
  disable_hostname = true
}
enable_syslog=true
log_level=\\\"INFO\\\"
syslog_facility=\\\"LOCAL1\\\"\" > /usr/local/etc/nomad/server.hcl

# set the rc startup
#sysrc nomad_enable=yes
service nomad enable
echo \"nomad_args=\\\"-config=/usr/local/etc/nomad/server.hcl -network-interface=\$IP\\\"\" >> /etc/rc.conf

## remote syslogs
if [ \"\${REMOTELOG}\" != \"0\" ]; then
    config_version=\$(/usr/local/sbin/syslog-ng --version | grep '^Config version:' | awk -F: '{ print \$2 }' | xargs)

    # read in template conf file, update remote log IP address, and
    # write to correct destination
    < /root/syslog-ng.conf.in \
      sed \"s|%%config_version%%|\$config_version|g\" | \
      sed \"s|%%remotelogip%%|\$REMOTELOG|g\" \
      > /usr/local/etc/syslog-ng.conf

    # stop and disable syslogd
    service syslogd onestop || true
    service syslogd disable

    # enable and start syslog-ng
    service syslog-ng enable
    sysrc syslog_ng_flags=\"-R /tmp/syslog-ng.persist\"
    service syslog-ng start
fi

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# start consul agent
#/usr/local/etc/rc.d/consul start
#service consul start
timeout --foreground 120 \
  sh -c 'while ! service consul status; do
    service consul start || true; sleep 5;
  done'

# start nomad
#/usr/local/etc/rc.d/nomad start
#service nomad start

timeout --foreground 120 \
  sh -c 'while ! service nomad status; do
    service nomad start || true; sleep 5;
  done'

# start node_exporter
#/usr/local/etc/rc.d/node_exporter start
service node_exporter start

# job imports
if [ \"\${IMPORTJOBS}\" -eq 1 ]; then
    echo \"Importing job files from /root/nomadjobs\"
    # set var /root/nomadjobs
    cd /root/nomadjobs/
    # count .nomad files in /root/nomadjobs
    JOBSCOUNT=\$(ls *.nomad |wc -l)
    # for each .nomad job file run nomad plan
    if [ \"\${JOBSCOUNT}\" -gt \"0\" ];then
        # get a file list of .nomad files
        JOBSLIST=\$(find . -type f -name \"*.nomad\")
        # nomad job plan /root/jobfiles/jobname.nomad
        for job in \$(echo \"\${JOBSLIST}\"); do
            /usr/local/bin/nomad job run -address=http://\"\${IP}\":4646 -detach \"\$job\";
        done
    fi
fi

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
