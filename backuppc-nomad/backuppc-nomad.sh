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
ASSUME_ALWAYS_YES=yes pkg bootstrap
touch /etc/rc.conf
service sendmail onedisable
sysrc -cq ifconfig_epair0b && sysrc -x ifconfig_epair0b || true

# Install packages
pkg install -y samba411 rsync rsync-bpc rrdtool par2cmdline p5-XML-RSS backuppc4 apache24 ap24-mod_scgi p5-SCGI 
pkg clean -y

# Create mountpoints
mkdir -p /var/db/BackupPC/
mkdir -p /home/backuppc
mkdir -p /home/backuppc/.ssh
mkdir -p /usr/local/etc/backuppc && mkdir -p /usr/local/etc/backuppc/pc
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
while getopts p: option
do
    case \"\${option}\"
    in
      p) PASSWORD=\${OPTARG};;
    esac
done

# Check config variables are set
if [ -z \${PASSWORD+x} ]; 
then 
    echo 'PASSWORD is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'PASSWORD is unset - see documentation how to configure this flavour'
    exit 1
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE ADJUSTED & COPIED:

mv /root/smb4.conf /usr/local/etc/ 
mv /root/backuppc.conf /usr/local/etc/apache24/Includes/

echo | sh /usr/local/etc/backuppc/update.sh 

sed -i .bak 's|^\$Conf{SCGIServerPort}.*|\$Conf{SCGIServerPort} = 10268;|g' /usr/local/etc/backuppc/config.pl
sed -i .bak 's|^\$Conf{CgiAdminUsers}.*|\$Conf{CgiAdminUsers}     = \"*\";|g' /usr/local/etc/backuppc/config.pl
sed -i .bak 's|^\$Conf{CgiImageDirURL}.*|\$Conf{CgiImageDirURL} = \"\";|g' /usr/local/etc/backuppc/config.pl

chown -R backuppc:backuppc /usr/local/etc/backuppc/
chown -R backuppc:backuppc /var/db/BackupPC/

# Change backuppc user to home directory for ssh keys file and fix .ssh permissions for files (possibly) having been copied in
chown -R backuppc:backuppc /home/backuppc/
chmod -R 700 /home/backuppc/.ssh
chmod 644 /home/backuppc/.ssh/*.pub || true
chmod 600 /home/backuppc/.ssh/id_rsa || true
[ -w /etc/master.passwd ] && sed -i '' \"s|BackupPC pseudo-user:/nonexistent|BackupPC pseudo-user:/home/backuppc|\" /etc/master.passwd
pwd_mkdb -p /etc/master.passwd

sysrc backuppc_enable=\"YES\" 

#htpasswd -b -c /usr/local/etc/backuppc/htpasswd backuppc \"\$PASSWORD\"
htpasswd -b -c /usr/local/etc/backuppc/htpasswd admin \"\$PASSWORD\" 
#ln -s /usr/local/www/cgi-bin/BackupPC_Admin /usr/local/www/cgi-bin/backuppc.pl

[ -w /usr/local/etc/apache24/httpd.conf ] && sed -i '' \"s|/usr/local/www/apache24/data|/usr/local/www/backuppc|\" /usr/local/etc/apache24/httpd.conf

sysrc apache24_enable=\"YES\"

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION
/usr/local/etc/rc.d/backuppc restart
killall httpd
/usr/local/etc/rc.d/apache24 restart


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
