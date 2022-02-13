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
service sshd enable

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

step "Install package sudo"
pkg install -y sudo

step "Install package curl"
pkg install -y curl

step "Install package jq"
pkg install -y jq

step "Install package jo"
pkg install -y jo

step "Install package nginx"
pkg install -y nginx

step "Install package goaccess"
pkg install -y goaccess

step "Install package acme.sh"
pkg install -y acme.sh

step "Install package openssl"
pkg install -y openssl

step "Install package rsync"
pkg install -y rsync

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
if [ -z \${SETUPSCRIPT+x} ]; then
    echo 'SETUPSCRIPT is unset - see documentation to configure this flavour to run a script'
    SETUPSCRIPT=0
fi
if [ -z \${IMPORTAUTHKEY+x} ]; then
    echo 'IMPORTAUTHKEY is unset - see documentation to configure this flavour for adding SSH keys to authorized_keys file.'
    IMPORTAUTHKEY=0
fi
if [ -z \${IMPORTSSH+x} ]; then
    echo 'IMPORTSSH is unset - see documentation to configure this flavour to import sshd config.'
    IMPORTSSH=0
fi
if [ -z \${IMPORTNGINX+x} ]; then
    echo 'IMPORTNGINX is unset - see documentation to configure this flavour to import nginx config.'
    IMPORTNGINX=0
fi
if [ -z \${IMPORTRSYNC+x} ]; then
    echo 'IMPORTRSYNC is unset - see documentation to configure this flavour to import rsync config.'
    IMPORTRSYNC=0
fi
if [ -z \${POSTSCRIPT+x} ]; then
    echo 'POSTSCRIPT is unset - see documentation to configure this flavour to run a script at the end'
    POSTSCRIPT=0
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# add custom commands to setup.sh such as directory creation or doing stuff to files
if [ \${SETUPSCRIPT} -eq 1 ]; then
    if [ -f /root/setup.sh ]; then
        chmod +x /root/setup.sh
        /root/setup.sh
    fi
fi

# create root ssh keys
mkdir -p /root/.ssh
/usr/bin/ssh-keygen -q -N '' -f /root/.ssh/id_rsa -t rsa
chown -R root:wheel /root/.ssh
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa

# add imported key to authorized_keys
if [ \${IMPORTAUTHKEY} -eq 1 ]; then
    if [ -f /root/authorized_keys_in ]; then
        echo \"Adding imported keys to /root/.ssh/authorized_keys\"
        cat /root/authorized_keys_in > /root/.ssh/authorized_keys
        chown -R root:wheel /root/.ssh
    else
        echo \"Error: no /root/authorized_keys_in file found\"
        echo \"#command=\\\"rsync --server --daemon .\\\",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding ssh-rsa key#\" > /root/.ssh/authorized_keys
    fi
fi

# setup ssh server with remote root access with a key
if [ \${IMPORTSSH} -eq 1 ]; then
    if [ -f /root/sshd_config_in ]; then
        echo \"Setting up ssh server\"
        cp -f /root/sshd_config_in /etc/ssh/sshd_config
        echo \"Manually setting up host keys\"
        cd /etc/ssh
        /usr/bin/ssh-keygen -A
        cd /root/
        echo \"Restarting ssh\"
        service sshd restart
    else
        echo \"There is no /root/sshd_config_in file\"
    fi
fi

# setup nginx and enable and start
if [ \${IMPORTNGINX} -eq 1 ]; then
    if [ -f /root/nginx.conf ]; then
        cp -f /root/nginx.conf /usr/local/etc/nginx/nginx.conf
        service nginx enable
        service nginx start
    else
        echo \"There is no /root/nginx.conf file\"
    fi
fi

# setup rsync
if [ \${IMPORTRSYNC} -eq 1 ]; then
    if [ -f /root/rsyncd.conf ]; then
        cp -f /root/rsyncd.conf /usr/local/etc/rsync/rsyncd.conf
    else
        echo \"There is no /root/rsyncd.conf file\"
    fi
fi

# goaccess
# this seems to be needed as install places in /usr/local/etc/goaccess.conf
# but default for goaccess is /usr/local/etc/goaccess/goaccess.conf
if [ -f /usr/local/etc/goaccess.conf ]; then
    ln -s /usr/local/etc/goaccess.conf /usr/local/etc/goaccess/goaccess.conf
fi
sysrc goaccess_log=\"/var/log/nginx/access.log\"
service goaccess enable

# add custom commands to postsetup.sh
if [ \${POSTSCRIPT} -eq 1 ]; then
    if [ -f /root/postsetup.sh ]; then
        chmod +x /root/postsetup.sh
        /root/postsetup.sh
    else
        echo \"There is no /root/postsetup.sh file\"
    fi
fi

#
# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

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
