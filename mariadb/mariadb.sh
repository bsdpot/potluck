#!/bin/sh

# Based on POTLUCK TEMPLATE v3.0
# Altered by Michael Gmelin
#
# EDIT THE FOLLOWING FOR NEW FLAVOUR:
# 1. RUNS_IN_NOMAD - true or false
# 2. Create a matching <flavour> file with this <flavour>.sh file that
#    contains the copy-in commands for the config files from <flavour>.d/
#    Remember that the package directories don't exist yet, so likely copy to /root
# 3. Adjust package installation between BEGIN & END PACKAGE SETUP
# 4. Check tarball extraction works for you between BEGIN & END EXTRACT TARBALL
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

step "Install mariadb105-server"
pkg install -y mariadb105-server

step "Clean package installation"
pkg clean -y

step "Create /var/db/mysql to support pot mount-in"
mkdir -p /var/db/mysql

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
/usr/local/etc/rc.d/mysql-server stop

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
while getopts s:u:d: option
do
    case \"\${option}\"
    in
      s) DUMPSCHEDULE=\${OPTARG};;
      u) DUMPUSER=\${OPTARG};;
      d) DUMPFILE=\${OPTARG};;
    esac
done

# Check config variables are set
if [ -z \${DUMPSCHEDULE+x} ]; 
then 
    echo 'Note: DUMPSCHEDULE is unset - no regular database dumps will be created' >> /var/log/cook.log
    echo 'Note: DUMPSCHEDULE is unset - no regular database dumps will be created'
fi

if [ -z \${DUMPUSER+x} ];
then
    echo 'DUMPUSER is unset - setting it to backupuser just in case' >> /var/log/cook.log
    echo 'DUMPUSER is unset - setting it to backupuser just in case'
    DUMPUSER=\"root\"
fi

if [ -z \${DUMPFILE+x} ];
then
    echo 'DUMPFILE is unset - setting it to /var/db/mysql/full_mariadb_backup.sql just in case' >> /var/log/cook.log
    echo 'DUMPFILE is unset - setting it to /var/db/mysql/full_mariadb_backup.sql just in case'
    DUMPFILE=\"/var/db/mysql/full_mariadb_backup.sql\"
fi

#
# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION
#
sysrc mysql_enable=YES

# Configure dump cronjob
if [ ! -z \${DUMPSCHEDULE+x} ];
then
   echo \"\$DUMPSCHEDULE       root   /usr/bin/nice -n 20 /usr/local/bin/mysqldump -u \$DUMPUSER -v --all-databases --all-tablespaces --routines --events --triggers --single-transaction > \$DUMPFILE 2>/var/log/dump.log\" >> /etc/crontab
fi

# We do not know if the database that is mounted from outside has already been run
# with this MariaDB release, so to be sure we upgrade it before we start the service
if [ -e /var/db/mysql/mysql ]
then
	chown -R mysql /var/db/mysql
	chgrp -R mysql /var/db/mysql
	chmod -R ug+rw /var/db/mysql
fi

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# If we do not find a database, we will initialise one
if [ ! -e /var/db/mysql/mysql ]
then
    /usr/local/etc/rc.d/mysql-server start
cat <<EOF | /usr/local/bin/mysql_secure_installation
y
0
y
y
y
y
y
EOF
else
    /usr/local/etc/rc.d/mysql-server start
    /usr/local/bin/mysql_upgrade
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
