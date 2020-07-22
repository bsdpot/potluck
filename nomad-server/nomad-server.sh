#!/bin/sh

# EDIT THE FOLLOWING FOR NEW FLAVOUR:
# 1. RUNS_IN_NOMAD - yes or no
# 2. Adjust package installation between BEGIN & END PACKAGE SETUP
# 3. Adjust jail configuration script generation between BEGIN & END COOK

# Set this to true if this jail flavour is to be created as a nomad (i.e. blocking) jail.
# You can then query it in the cook script generation below and the script is installed
# appropriately at the end of this script 
RUNS_IN_NOMAD=false

# -------------- BEGIN PACKAGE SETUP -------------
[ -w /etc/pkg/FreeBSD.conf ] && sed -i '' 's/quarterly/latest/' /etc/pkg/FreeBSD.conf
ASSUME_ALWAYS_YES=yes pkg bootstrap
touch /etc/rc.conf
sysrc sendmail_enable="NO"
sysrc nomad_enable="YES"
sysrc nomad_user="root"
sysrc nomad_env="PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/sbin:/bin"

# Install packages
pkg install -y nomad 
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

# ----------------- BEGIN COOK ------------------ 
echo "#!/bin/sh

# No need to change this, just ensures configuration is done only once
if [ -e /usr/local/etc/pot-is-seasoned ]
then
    # If this pot flavour is blocking (i.e. it should not return), there is no /tmp/environment.sh
    # created by pot and we block indefinitely
    if [ ! -e /tmp/environment.sh ]
    then
        tail -f /dev/null 
    fi
    exit 0
fi

# ADJUST THIS: STOP SERVICES AS NEEDED BEFORE CONFIGURATION
/usr/local/etc/rc.d/nomad stop  || true

# No need to adjust this:
# If this pot flavour is not blocking, we need to read the environment first from /tmp/environment.sh
# where pot is storing it in this case
if [ -e /tmp/environment.sh ]
then
    . /tmp/environment.sh
fi

#
# ADJUST THIS BY CHECKING FOR ALL VARIABLES YOUR FLAVOUR NEEDS:
# Check config variables are set
#
if [ -z \${DATACENTER+x} ]; 
then 
    echo 'DATACENTER is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${IP+x} ]; 
then 
    echo 'IP is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${CONSULSERVER+x} ];
then
    echo 'CONSULSERVER is unset - see documentation how to configure this flavour'
    exit 1
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# Create nomad server config file 
echo \"
bind_addr = \\\"\$IP\\\"
plugin_dir = \\\"/usr/local/libexec/nomad/plugins\\\"
datacenter = \\\"\$DATACENTER\\\"

advertise {
  # This should be the IP of THIS MACHINE and must be routable by every node
  # in your cluster
  http = \\\"\$IP:4646\\\"
}

server {
  enabled = true
  bootstrap_expect = 1
}

consul {
  # The address to the Consul agent.
  address = \\\"\$CONSULSERVER:8500\\\"

  # The service name to register the server and client with Consul.
  server_service_name = \\\"\$DATACENTER-server\\\"

  # Enables automatically registering the services.
  auto_advertise = true

  # Enabling the server and client to bootstrap using Consul.
  server_auto_join = true
}

enable_syslog=true
log_level=\\\"INFO\\\"
syslog_facility=\\\"LOCAL1\\\"\" > /usr/local/etc/nomad/server.hcl
echo \"nomad_args=\\\"-config=/usr/local/etc/nomad/server.hcl -network-interface=\$IP\\\"\" >> /etc/rc.conf

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION
/usr/local/etc/rc.d/nomad start

# Do not touch this:
touch /usr/local/etc/pot-is-seasoned

# If this pot flavour is blocking (i.e. it should not return), there is no /tmp/environment.sh
# created by pot and we now after configuration block indefinitely
if [ ! -e /tmp/environment.sh ]
then
    tail -f /dev/null
fi
" > /usr/local/bin/cook

# ----------------- END COOK ------------------


# ---------- NO NEED TO EDIT BELOW ------------

chmod u+x /usr/local/bin/cook

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
echo "#!/bin/sh

#
# PROVIDE: cook 
# REQUIRE: LOGIN
# KEYWORD: shutdown
#

. /etc/rc.subr

name=cook
rcvar=cook_enable

load_rc_config $name

: ${cook_enable:=\"NO\"}
: ${cook_env:=\"\"}

command=\"/usr/local/bin/cook\"
command_args=\"\"

run_rc_command \"\$1\"
" > /usr/local/etc/rc.d/cook

chmod u+x /usr/local/etc/rc.d/cook

if [ $RUNS_IN_NOMAD = false ]
then
    # This is a non-nomad (non-blocking) jail, so we need to make sure the script
    # gets started when the jail is started:
    # Otherwise, /usr/local/bin/cook will be set as start script by the pot flavour
    echo "cook_enable=\"YES\"" >> /etc/rc.conf
fi
