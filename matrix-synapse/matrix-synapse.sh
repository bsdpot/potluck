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
# shellcheck disable=SC2016
#echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest" }' \
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

step "Install package openssl"
pkg install -y openssl

step "Install package jq"
pkg install -y jq

step "Install package jo"
pkg install -y jo

step "Install package curl"
pkg install -y curl

step "Install package matrix server"
pkg install -y py38-matrix-synapse

step "Install package matrix ldap support"
pkg install -y py38-matrix-synapse-ldap3

step "Install package acme.sh"
pkg install -y acme.sh

step "Install package nginx"
pkg install -y nginx

step "Clean package installation"
pkg clean -y

step "Create necessary directories if they don't exist"
# create some necessary directories
mkdir -p /var/log/matrix-synapse
mkdir -p /var/run/matrix-synapse
mkdir -p /usr/local/etc/matrix-synapse
mkdir -p /usr/local/www/well-known/matrix

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
step "Clean cook artifacts"
rm -rf /usr/local/bin/cook

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
if [ -z \${IP+x} ]; then
    echo 'IP is unset - see documentation how to pass in the IP address as a parameter'
    exit 1
fi
if [ -z \${DOMAIN+x} ]; then
    echo 'DOMAIN is unset - see documentation how to pass in a domain name as a parameter'
    exit 1
fi
if [ -z \${ALERTEMAIL+x} ]; then
    echo 'ALERTEMAIL is unset - see documentation for how to pass in the alert email address as a parameter'
    exit 1
fi
if [ -z \${REGISTRATIONENABLE+x} ]; then
    echo 'REGISTRATIONENABLE is unset - defaulting to false - see documentation for how to set true or false to enable registrations'
    REGISTRATIONENABLE=false
fi
if [ -z \${MYSHAREDSECRET+x} ]; then
    echo 'MYSHAREDSECRET is unset - please provide a shared secret - see documentation for how to pass this in as a parameter'
    exit 1
fi
if [ -z \${SMTPHOST+x} ]; then
    echo 'SMTPHOST is unset - please include the mail host - see documentation for how to pass in the mail host as a parameter'
    exit 1
fi
if [ -z \${SMTPPORT+x} ]; then
    echo 'SMTPPORT is unset - defaulting to port 25 - see documentation for how to pass in the smtp port as a parameter'
    SMTPPORT=25
fi
if [ -z \${SMTPUSER+x} ]; then
    echo 'SMTPUSER is unset - see documentation for how to pass in a smtp username as a parameter'
    exit 1
fi
if [ -z \${SMTPPASS+x} ]; then
    echo 'SMTPPASS is unset - see documentation for how to pass in a smtp password as a parameter'
    exit 1
fi
if [ -z \${SMTPFROM+x} ]; then
    echo 'SMTPFROM is unset - see documentation for how to pass in the from address as a parameter'
    exit 1
fi
if [ -z \${LDAPSERVER+x} ]; then
    echo 'LDAPSERVER is unset - see documentation for how to pass in the LDAP server as a parameter'
    exit 1
fi
if [ -z \${LDAPPASSWORD+x} ]; then
    echo 'LDAPPASSWORD is unset - see documentation for how to pass in the LDAP password as a parameter'
    exit 1
fi
if [ -z \${LDAPDOMAIN+x} ]; then
    echo 'LDAPDOMAIN is unset - see documentation how to pass in the LDAP domain name as a parameter'
    exit 1
fi
if [ -z \${NOSSL+x} ]; then
    echo 'NOSSL is unset - default true - see documentation for how to enable SSL'
    NOSSL=true
fi
if [ -z \${CONTROLUSER+x} ]; then
    echo 'CONTROLUSER is unset - default false - see documentation for how to enable a control user SSH with authorized_keys file'
    CONTROLUSER=false
fi
if [ -z \${SSLEMAIL+x} ]; then
    echo 'SSLEMAIL is unset - see documentation for how to set email address for acme.sh regitration'
    exit 1
fi

#
# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files
#
# Important there MUST be empty lines between the config sections
#

# check that /mnt/matrixdata exists
if [ -d /mnt/matrixdata ]; then
    echo \"INFO: /mnt/matrixdata exists. All good.\"
else
    echo \"ERROR: /mnt/matrixdata does not exist. Where is the persistent storage?\"
    exit 1
fi

# make dirs
mkdir -p /mnt/matrixdata/matrix-synapse
mkdir -p /mnt/matrixdata/media_store
mkdir -p /mnt/matrixdata/control
mkdir -p /usr/local/www/well-known/matrix

# double check permissions on directories
chown synapse /mnt/matrixdata
chown -R synapse /mnt/matrixdata/matrix-synapse
chmod -R ugo+rw /mnt/matrixdata/matrix-synapse
chown -R synapse /mnt/matrixdata/media_store
chmod -R ugo+rw /mnt/matrixdata/media_store
chown -R synapse /var/log/matrix-synapse
chown -R synapse /var/run/matrix-synapse

# split domain into parts for use in matrix-synapse ldap configuration
MYSUFFIX=\$(echo \${LDAPDOMAIN} | awk -F '.' 'NF>=2 {print \$(NF-1)}')
MYTLD=\$(echo \${LDAPDOMAIN} | awk -F '.' 'NF>=2 {print \$(NF)}')
echo \"From domain name of \${LDAPDOMAIN} we get MYSUFFIX of \${MYSUFFIX} and MYTLD of \${MYTLD}\"

# generate macaroon and form key
MYMACAROON=\$(/usr/bin/openssl rand -base64 48)
MYFORMKEY=\$(/usr/bin/openssl rand -base64 48)

# copy over log config
if [ -f /root/my.log.config ]; then
    cp -f /root/my.log.config /usr/local/etc/matrix-synapse/my.log.config
fi

# generate basic setup
/usr/local/bin/python3.8 -B -m synapse.app.homeserver -c /usr/local/etc/matrix-synapse/homeserver.yaml --generate-config -H \${DOMAIN} --report-stats no

mv /usr/local/etc/matrix-synapse/homeserver.yaml /usr/local/etc/matrix-synapse/homeserver.yaml.generated

# set variables and copy over homeserver.yaml
if [ -f /root/homeserver.yaml ]; then
    sed < /root/homeserver.yaml \
    -e \"s|%%DOMAIN%%|\${DOMAIN}|g\" \
    -e \"s|%%ALERTEMAIL%%|\${ALERTEMAIL}|g\" \
    -e \"s|%%REGISTRATIONENABLE%%|\${REGISTRATIONENABLE}|g\" \
    -e \"s|%%MYSHAREDSECRET%%|\${MYSHAREDSECRET}|g\" \
    -e \"s|%%MYMACAROON%%|\${MYMACAROON}|g\" \
    -e \"s|%%MYFORMKEY%%|\${MYFORMKEY}|g\" \
    -e \"s|%%SMTPHOST%%|\${SMTPHOST}|g\" \
    -e \"s|%%SMTPPORT%%|\${SMTPPORT}|g\" \
    -e \"s|%%SMTPUSER%%|\${SMTPUSER}|g\" \
    -e \"s|%%SMTPPASS%%|\${SMTPPASS}|g\" \
    -e \"s|%%LDAPSERVER%%|\${LDAPSERVER}|g\" \
    -e \"s|%%MYSUFFIX%%|\${MYSUFFIX}|g\" \
    -e \"s|%%MYTLD%%|\${MYTLD}|g\" \
    -e \"s|%%LDAPPASSWORD%%|\${LDAPPASSWORD}|g\" > /usr/local/etc/matrix-synapse/homeserver.yaml
else
    echo \"Error: no /root/homeserver.yaml file to modify. This error should not happen in prebuilt pot image.\"
fi


# enable matrix
service synapse enable

# setup control user
# sshd (control user)
if [ \${CONTROLUSER} = yes ]; then
    pw user add -n control -c 'Control Account' -d /mnt/matrixdata/control -G wheel -m -s /bin/sh
    mkdir -p /mnt/matrixdata/control/.ssh
    chown control:control /mnt/matrixdata/control/.ssh
    # copy in importauthkey to enable a specific pubkey access
    if [ -f /root/importauthkey ]; then
        cat /root/importauthkey > /mnt/matrixdata/control/.ssh/authorized_keys
    else
        touch /mnt/matrixdata/control/.ssh/authorized_keys
    fi
    chown control:control /mnt/matrixdata/control/.ssh/authorized_keys
    chmod u+rw /mnt/matrixdata/control/.ssh/authorized_keys
    chmod go-w /mnt/matrixdata/control/.ssh/authorized_keys
    echo \"StrictModes no\" >> /etc/ssh/sshd_config
    service sshd enable
    service sshd restart
fi

# setup nginx.conf
if [ \${NOSSL} = true ]; then
    MATRIXPORT=80
    if [ -f /root/nginx.nossl.conf ]; then
        sed < /root/nginx.nossl.conf \
        -e \"s|%%DOMAIN%%|\${DOMAIN}|g\" > /usr/local/etc/nginx/nginx.conf
    else
        echo \"Error: no /root/nginx.nossl.conf file to modify. This error should not happen in prebuilt pot image.\"
    fi
    if [ -f /root/server.in ]; then
        sed < /root/server.in \
        -e \"s|%%DOMAIN%%|\${DOMAIN}|g\" \
        -e \"s|%%MATRIXPORT%%|\${MATRIXPORT}|g\" > /usr/local/www/well-known/matrix/server
    else
        echo \"Error: no /root/server.in file to modify. This error should not happen in prebuilt pot image.\"
    fi
else
    MATRIXPORT=443
    if [ -f /root/nginx.conf ]; then
        sed < /root/nginx.conf \
        -e \"s|%%DOMAIN%%|\${DOMAIN}|g\" > /usr/local/etc/nginx/nginx.conf
    else
        echo \"Error: no /root/nginx.conf file to modify. This error should not happen in prebuilt pot image.\"
    fi
    if [ -f /root/server.in ]; then
        sed < /root/server.in \
        -e \"s|%%DOMAIN%%|\${DOMAIN}|g\" \
        -e \"s|%%MATRIXPORT%%|\${MATRIXPORT}|g\" > /usr/local/www/well-known/matrix/server
    else
        echo \"Error: no /root/server.in file to modify. This error should not happen in prebuilt pot image.\"
    fi
    # ssl steps
    if [ -f /root/certrenew.sh ]; then
        sed -i .orig -e \"s|%%SSLEMAIL%%|\${SSLEMAIL}|g\" -e \"s|%%DOMAIN%%|\${DOMAIN}|g\" /root/certrenew.sh
        chmod u+x /root/certrenew.sh
        echo \"30      4       1       *       *       root   /bin/sh /root/certrenew.sh\" >> /etc/crontab
    fi
fi

# enable nginx
service nginx enable

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# run certificate renewal script
if [ \${NOSSL} = false ]; then
    echo \"Generating certificates then starting services with SSL\"
    cd /root
    /usr/local/sbin/acme.sh --register-account -m \${SSLEMAIL} --server zerossl
    /usr/local/sbin/acme.sh --force --issue -d \${DOMAIN} --standalone
    cp -f /.acme.sh/\${DOMAIN}/* /usr/local/etc/ssl/
    if [ -f /usr/local/etc/ssl/\${DOMAIN}.key ]; then
        service nginx start
        service synapse start
    else
        echo \"Error: where is /usr/local/etc/ssl/\${DOMAIN}.key?\"
    fi
else
    echo \"Starting services without SSL\"
    service synapse start
    service nginx start
fi

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
