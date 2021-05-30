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
service sendmail onedisable

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

# we need consul for consul agent
step "Install package consul"
pkg install -y consul

step "Install package vault"
pkg install -y vault

step "Add vault user to daemon class"
pw usermod vault -G daemon

step "Install package sudo"
pkg install -y sudo

step "Install package node_exporter"
pkg install -y node_exporter

step "Install package jq"
pkg install -y jq

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
/usr/local/etc/rc.d/consul onestop || true
/usr/local/etc/rc.d/vault onestop  || true

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
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen for the consul flavour.
# Re-used for nomad, which is usually 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the one from the consul flavour
if [ -z \${GOSSIPKEY+x} ];
then
    echo 'GOSSIPKEY is unset - see documentation how to configure this flavour, defaulting to preset encrypt key. Do not use this in production!'
    GOSSIPKEY='\"BY+vavBUSEmNzmxxS3k3bmVFn1giS4uEudc774nBhIw=\"'
fi
# set to 1 or yes to provide an unseal token to a secondary node for autounseal
# this defaults to off for a primary node which still needs vault operator init performed to get unseal keys and token
if [ -z \${VAULTTYPE+x} ];
then
    echo 'VAULTTYPE is unset - see documentation how to configure this flavour, defaulting to unseal instead of cluster.'
    VAULTTYPE=\"unseal\"
fi
# IP address of the unseal server
if [ -z \${UNSEALIP+x} ];
then
    echo 'UNSEALIP is unset - see documentation how to configure this flavour, defaulting to preset value. Do not use this in production!'
    UNSEALIP=\"127.0.0.1\"
fi
# Unwrap token to pass into cluster
if [ -z \${UNSEALTOKEN+x} ];
then
    echo 'UNSEALTOKEN is unset - see documentation how to configure this flavour, defaulting to unset value. Do not use this in production!'
    UNSEALTOKEN=\"unset\"
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

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
 \\\"log_file\\\": \\\"/var/log/consul/\\\",
 \\\"log_level\\\": \\\"WARN\\\",
 \\\"encrypt\\\": \$GOSSIPKEY,
 \\\"start_join\\\": [ \$CONSULSERVERS ],
 \\\"service\\\": {
  \\\"name\\\": \\\"node-exporter\\\",
  \\\"tags\\\": [\\\"_app=vault\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\"],
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

# enable node_exporter service
sysrc node_exporter_enable=\"YES\"

## start Vault

if [ -f /usr/local/etc/vault/vault-server.hcl ]; then
    rm /usr/local/etc/vault/vault-server.hcl
fi

# default freebsd vault.hcl is /usr/local/etc/vault.hcl and
# the init script /usr/local/etc/rc.d/vault refers to this
# but many vault docs refer to /usr/local/etc/vault/vault-server.hcl
# or similar

# Create vault configuration file
# if UNSEAL is set to 1 or YES then we want to include the token for automatic unseal

case \$VAULTTYPE in
  # -E VAULTTYPE=\\\"unseal\\\"
  unseal)
    echo \"disable_mlock = true
ui = true
listener \\\"tcp\\\" {
  address = \\\"\$IP:8200\\\"
  tls_disable = 1
}
# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
storage \\\"file\\\" {
  path    = \\\"/mnt/vault-unseal\\\"
}
api_addr = \\\"http://\$IP:8200\\\"
\" > /usr/local/etc/vault.hcl

    # setup autounseal config
    echo \"path \\\"transit/encrypt/autounseal\\\" {
  capabilities = [ \\\"update\\\" ]
}
path \\\"transit/decrypt/autounseal\\\" {
  capabilities = [ \\\"update\\\" ]
}
\" > /root/autounseal.hcl

    # do not unwrap
    UNWRAPME=0
     ;;

  # -E VAULTTYPE=\\\"cluster\\\"
  cluster)
    echo \"disable_mlock = true
ui = true
listener \\\"tcp\\\" {
  address = \\\"\$IP:8200\\\"
  cluster_address = \\\"\$IP:8201\\\"
  tls_disable = 1
}
# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
storage \\\"raft\\\" {
  path    = \\\"/mnt\\\"
  node_id = \\\"\$NODENAME\\\"
}
# we are a secondary server joining a cluster
seal \\\"transit\\\" {
  address = \\\"http://\$UNSEALIP:8200\\\"
  disable_renewal = \\\"false\\\"
  key_name = \\\"autounseal\\\"
  mount_path = \\\"transit/\\\"
  token = \\\"UNWRAPPEDTOKEN\\\"
  #tls_ca_cert = \\\"/etc/pem/vault.pem\\\"
  #tls_client_cert = \\\"/etc/pem/client_cert.pem\\\"
  #tls_client_key = \\\"/etc/pem/ca_cert.pem\\\"
  #tls_server_name = \\\"vault\\\"
  #tls_skip_verify = \\\"false\\\"
}
service_registration \\\"consul\\\" {
  address = \\\"\$IP:8500\\\"
  scheme = \\\"http\\\"
  service = \\\"vault\\\"
  #tls_ca_file = \\\"/etc/pem/vault.ca\\\"
  #tls_cert_file = \\\"/etc/pem/vault.cert\\\"
  #tls_key_file = \\\"/etc/pem/vault.key\\\"
}
api_addr = \\\"http://\$IP:8200\\\"
cluster_addr = \\\"http://\$IP:8201\\\"
\" > /usr/local/etc/vault.hcl

    # we want to unwrap with the passed in token
    UNWRAPME=1
    ;;

  *)
    echo \"there is a problem with the VAULTTYPE variable - set to unseal or cluster\"
    exit 1
    ;;

esac

# set permissions on /mnt for vault data
chown -R vault:wheel /mnt

# setup rc.conf entries
# we do not set vault_user=vault because vault will not start
sysrc vault_enable=yes
sysrc vault_login_class=root

#
# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# start consul agent
/usr/local/etc/rc.d/consul start

# start node_exporter
/usr/local/etc/rc.d/node_exporter start

# if we need to autounseal with passed in unwrap token
if [ \$UNWRAPME -eq 1 ]; then
    /usr/local/bin/vault unwrap -address=http://\$UNSEALIP:8200 -format=json \$UNSEALTOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/unseal.token
    VAULT_TOKEN=\$(/bin/cat /root/unseal.token)
    /usr/bin/sed -i .orig \"/UNWRAPPEDTOKEN/s/UNWRAPPEDTOKEN/\$VAULT_TOKEN/g\" /usr/local/etc/vault.hcl
fi

# start vault
/usr/local/etc/rc.d/vault start


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
