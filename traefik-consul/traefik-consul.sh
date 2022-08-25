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

step "Install package sudo"
pkg install -y sudo

step "Install package consul"
pkg install -y consul

step "Install package traefik"
pkg install -y traefik

step "Enable Traefik startup"
sysrc traefik_enable="YES"

step "Install package syslog-ng"
pkg install -y syslog-ng

step "Install package node_exporter"
pkg install -y node_exporter

step "Clean package installation"
pkg clean -y

# To allow mount in of this directory, create mountpoint
step "Create legacy mount in"
mkdir -p /var/log/traefik

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
service traefik onestop || true

# No need to adjust this:
# If this pot flavour is not blocking, we need to read the environment first from /tmp/environment.sh
# where pot is storing it in this case
if [ -e /tmp/environment.sh ]; then
    . /tmp/environment.sh
fi
#
# ADJUST THIS BY CHECKING FOR ALL VARIABLES YOUR FLAVOUR NEEDS:
# Check config variables are set
#
if [ -z \${CONSULSERVER+x} ]; then
    echo 'CONSULSERVER is unset - see documentation how to configure this flavour'
    exit 1
fi
# Remotelog is a remote syslog server, need to pass in IP
if [ -z \${REMOTELOG+x} ]; then
    echo 'REMOTELOG is unset - see documentation how to configure this flavour'
    REMOTELOG=0
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files
# Create traefik server config file
echo \"
[entryPoints]
  [entryPoints.http]
    address = \\\"0.0.0.0:8080\\\"
  [entryPoints.traefik]
    address = \\\"0.0.0.0:9002\\\"
  [entryPoints.httpSSL]
    address = \\\"0.0.0.0:8443\\\"
  [entryPoints.metrics]
    address = \\\"0.0.0.0:8082\\\"

[http.routers.my-api]
  entryPoints = [\\\"traefik\\\"]
  # Catch every request (only available rule for non-tls routers. See below.)
  rule = \\\"HostSNI(\`*\`)\\\"
  service = \\\"api@internal\\\"

[[tls.certificates]]
  certFile = \\\"/usr/local/etc/ssl/cert.crt\\\"
  keyFile = \\\"/usr/local/etc/ssl/cert.key\\\"

[tls.options]
  [tls.options.myTLSOptions]
    minVersion = \\\"VersionTLS12\\\"
    cipherSuites = [
      \\\"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\\\",
      \\\"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\\\",
      \\\"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256\\\",
      \\\"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256\\\",
      \\\"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\\\",
      \\\"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\\\",
    ]

[api]
  dashboard = true
  insecure = true

[log]
  filePath = \\\"/var/log/traefik/traefik.log\\\"

[accessLog]
  filePath = \\\"/var/log/traefik/traefik-access.log\\\"

[metrics]
  [metrics.prometheus]
    entryPoint = \\\"metrics\\\"
    buckets = [0.1,0.3,1.2,5.0]
    addEntryPointsLabels = true
    addRoutersLabels = true
    addServicesLabels = true

[providers.consulCatalog]
  stale = false
  exposedByDefault = true
  [providers.consulCatalog.endpoint]
    address = \\\"\$CONSULSERVER:8500\\\"\" > /usr/local/etc/traefik.toml

echo \"traefik_conf=\\\"/usr/local/etc/traefik.toml\\\"\" >> /etc/rc.conf

touch /var/log/traefik/traefik.log
touch /var/log/traefik/traefik-access.log
chown traefik:traefik /var/log/traefik/traefik.log
chown traefik:traefik /var/log/traefik/traefik-access.log

mkdir -p /usr/local/etc/ssl/
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /usr/local/etc/ssl/cert.key -out /usr/local/etc/ssl/cert.crt -subj \"/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com\"
chmod 644 /usr/local/etc/ssl/cert.crt
chmod 600 /usr/local/etc/ssl/cert.key

## remote syslogs
if [ \"\${REMOTELOG}\" != \"0\" ]; then
  config_version=\$(/usr/local/sbin/syslog-ng --version | grep '^Config version:' | awk -F: '{ print \$2 }' | xargs)

  # read in template conf file, update remote log IP address, and
  # write to correct destination
  < /root/syslog-ng.conf.in \
    sed \"s|%%config_version%%|\$config_version|g\" | \
    sed \"s|%%remotelogip%%|\$REMOTELOG|g\" > /usr/local/etc/syslog-ng.conf

    # stop and disable syslogd
    service syslogd onestop || true
    service syslogd disable

    # enable and start syslog-ng
    service syslog-ng enable
    sysrc syslog_ng_flags=\"-R /tmp/syslog-ng.persist\"
    service syslog-ng start
fi

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION
#/usr/local/etc/rc.d/traefik start

service traefik start

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


# Create rc.d script for "normal" mode:
step "Create rc.d script to start cook"
echo "creating rc.d script to start cook" | tee -a $COOKLOG

# shellcheck disable=SC2016
echo '#!/bin/sh
#
# PROVIDE: cook
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
. /etc/rc.subr
name="cook"
rcvar="cook_enable"
load_rc_config $name
: ${cook_enable:="NO"}
: ${cook_env:=""}
command="/usr/local/bin/cook"
command_args=""
run_rc_command "$1"
' > /usr/local/etc/rc.d/cook

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
