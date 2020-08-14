#!/bin/sh

# POTLUCK TEMPLATE v2.0
# EDIT THE FOLLOWING FOR NEW FLAVOUR:
# 1. RUNS_IN_NOMAD - yes or no
# 2. Create a matching <flavour> file with this <flavour>.sh file that
#    contains the copy-in commands for the config files from <flavour>.d/
#    Remember that the package directories don't exist yet, so likely copy to /root
# 3. Adjust package installation between BEGIN & END PACKAGE SETUP
# 4. Adjust jail configuration script generation between BEGIN & END COOK
#    Configure the config files that have been copied in where necessary

# Set this to true if this jail flavour is to be created as a nomad (i.e. blocking) jail.
# You can then query it in the cook script generation below and the script is installed
# appropriately at the end of this script 
RUNS_IN_NOMAD=true

# -------- BEGIN PACKAGE & MOUNTPOINT SETUP -------------
[ -w /etc/pkg/FreeBSD.conf ] && sed -i '' 's/quarterly/latest/' /etc/pkg/FreeBSD.conf
ASSUME_ALWAYS_YES=yes pkg bootstrap
touch /etc/rc.conf
sysrc sendmail_enable="NO"

# Install packages
pkg install -y py37-matrix-synapse py37-matrix-synapse-ldap3 acme.sh nginx 
pkg clean -y

# Create mountpoints
mkdir -p /var/db/control
mkdir -p /var/db/matrix-synapse
# ---------- END PACKAGE & MOUNTPOINT SETUP -------------

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
RUNS_IN_NOMAD=$RUNS_IN_NOMAD
# No need to change this, just ensures configuration is done only once
if [ -e /usr/local/etc/pot-is-seasoned ]
then
    # If this pot flavour is blocking (i.e. it should not return), 
    # we block indefinitely
    if [ \$RUNS_IN_NOMAD ]
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

# Convert parameters to variables if passed (overwrite environment)
while getopts s:e:r:k:h:u:p:l:b:d:w: option
do
    case \"\${option}\"
    in
      s) SERVERNAME=\${OPTARG};;
      e) ADMINEMAIL=\${OPTARG};;
      r) ENABLEREGISTRATION=\${OPTARG};;
      k) SHAREDSECRET=\${OPTARG};;
      h) SMTPHOST=\${OPTARG};;
      u) SMTPUSER=\${OPTARG};;
      p) SMTPPWD=\${OPTARG};;
      l) LDAPURI=\${OPTARG};;
      b) LDAPBASE=\${OPTARG};;
      d) LDAPBINDDN=\${OPTARG};;
      w) LDAPBINDPWD=\${OPTARG};;
    esac
done

# Check config variables are set
if [ -z \${SERVERNAME+x} ]; 
then 
    echo 'SERVERNAME is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'SERVERNAME is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${ADMINEMAIL+x} ];
then
    echo 'ADMINEMAIL is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'ADMINEMAIL is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${ENABLEREGISTRATION+x} ];
then
    echo 'ENABLEREGISTRATION is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'ENABLEREGISTRATION is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${SHAREDSECRET+x} ];
then
    echo 'SHAREDSECRET is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'SHAREDSECRET is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${SMTPHOST+x} ];
then
    echo 'SMTPHOST is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'SMTPHOST is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${SMTPUSER+x} ];
then
    echo 'SMTPUSER is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'SMTPUSER is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${SMTPPWD+x} ];
then
    echo 'SMTPPWD is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'SMTPPWD is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ ! -z \${LDAPURI+x} ];
then
    if [ -z \${LDAPBASE+x} ];
    then
        echo 'LDAPURI is set but LDAPBASE is unset - see documentation how to configure this flavour' >> /var/log/cook.log
        echo 'LDAPURI is set but LDAPBASE is unset - see documentation how to configure this flavour'
        exit 1
    fi
    if [ -z \${LDAPBINDDN+x} ];
    then
        echo 'LDAPURI is set but LDAPBINDDN is unset - see documentation how to configure this flavour' >> /var/log/cook.log
        echo 'LDAPURI is set but LDAPBINDDN is unset - see documentation how to configure this flavour'
        exit 1
    fi
    if [ -z \${LDAPBINDPWD+x} ];
    then
        echo 'LDAPURI is set but LDAPBINDPWD is unset - see documentation how to configure this flavour' >> /var/log/cook.log
        echo 'LDAPURI is set but LDAPBINDPWD is unset - see documentation how to configure this flavour'
        exit 1
    fi
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE ADJUSTED & COPIED:

# homeserver.yaml
[ -w /root/homeserver.yaml ] && sed -i '' \"s/\\\$SERVERNAME/\$SERVERNAME/\" /root/homeserver.yaml 
[ -w /root/homeserver.yaml ] && sed -i '' \"s/\\\$ADMINEMAIL/\$ADMINEMAIL/\" /root/homeserver.yaml
[ -w /root/homeserver.yaml ] && sed -i '' \"s/\\\$ENABLEREGISTRATION/\$ENABLEREGISTRATION/\" /root/homeserver.yaml
[ -w /root/homeserver.yaml ] && sed -i '' \"s/\\\$SHAREDSECRET/\$SHAREDSECRET/\" /root/homeserver.yaml
[ -w /root/homeserver.yaml ] && sed -i '' \"s/\\\$SMTPHOST/\$SMTPHOST/\" /root/homeserver.yaml
[ -w /root/homeserver.yaml ] && sed -i '' \"s/\\\$SMTPUSER/\$SMTPUSER/\" /root/homeserver.yaml
[ -w /root/homeserver.yaml ] && sed -i '' \"s/\\\$SMTPPWD/\$SMTPPWD/\" /root/homeserver.yaml

# homeserver.yaml.ldappart
if [ -z \${LDAPURI+x} ];
then
    rm /root/homeserver.yaml.ldappart
else
    [ -w /root/homeserver.yaml.ldappart ] && sed -i '' \"s#\\\$LDAPURI#\$LDAPURI#\" /root/homeserver.yaml.ldappart
    [ -w /root/homeserver.yaml.ldappart ] && sed -i '' \"s/\\\$LDAPBASE/\$LDAPBASE/\" /root/homeserver.yaml.ldappart
    [ -w /root/homeserver.yaml.ldappart ] && sed -i '' \"s/\\\$LDAPBINDDN/\$LDAPBINDDN/\" /root/homeserver.yaml.ldappart
    [ -w /root/homeserver.yaml.ldappart ] && sed -i '' \"s/\\\$LDAPBINDPWD/\$LDAPBINDPWD/\" /root/homeserver.yaml.ldappart

    cat /root/homeserver.yaml.ldappart >> /root/homeserver.yaml
fi

/usr/local/bin/python3.7 -B -m synapse.app.homeserver -c /usr/local/etc/matrix-synapse/homeserver.yaml --generate-config -H \$SERVERNAME --report-stats no

mkdir -p /var/db/media_store
chmod ugo+rw /var/db/media_store

# ...we bring our own config though, so we backup & replace the generated one
mv /usr/local/etc/matrix-synapse/homeserver.yaml /usr/local/etc/matrix-synapse/homeserver.yaml.generated
mv /root/homeserver.yaml /usr/local/etc/matrix-synapse

# homeserver.log.config
mv /root/homeserver.log.config /usr/local/etc/matrix-synapse


# nginx.conf
[ -w /root/nginx.conf ] && sed -i '' \"s/\\\$SERVERNAME/\$SERVERNAME/\" /root/nginx.conf
mkdir -p /usr/local/etc/nginx
mv /root/nginx.conf /usr/local/etc/nginx

# certrenew.sh
[ -w /root/nginx.conf ] && sed -i '' \"s/\\\$SERVERNAME/\$SERVERNAME/\" /root/nginx.conf
chmod u+x /root/certrenew.sh
echo \"30      4       1       *       *       root   /bin/sh /root/certrenew.sh\" >> /etc/crontab 

# sshd (control user)
pw user add -n control -c 'Control Account' -d /var/db/control -G wheel -m -s /bin/sh
mkdir -p /var/db/control/.ssh
chown control:control /var/db/control/.ssh
touch /var/db/control/.ssh/authorized_keys
chown control:control /var/db/control/.ssh/authorized_keys
chmod u+rw /var/db/control/.ssh/authorized_keys
chmod go-w /var/db/control/.ssh/authorized_keys
echo \"StrictModes no\" >> /etc/ssh/sshd_config

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION
sysrc synapse_enable=\"YES\"
sysrc nginx_enable=\"YES\"
sysrc sshd_enable=\"YES\"

/usr/local/etc/rc.d/synapse start
/usr/local/etc/rc.d/nginx start
/etc/rc.d/sshd start

. /root/certrenew.sh

# Do not touch this:
touch /usr/local/etc/pot-is-seasoned
# If this pot flavour is blocking (i.e. it should not return), there is no /tmp/environment.sh
# created by pot and we now after configuration block indefinitely
if [ \$RUNS_IN_NOMAD ]
then
    /bin/sh /etc/rc
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

