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

# -------------- BEGIN PACKAGE SETUP -------------
[ -w /etc/pkg/FreeBSD.conf ] && sed -i '' 's/quarterly/latest/' /etc/pkg/FreeBSD.conf
ASSUME_ALWAYS_YES=yes pkg bootstrap
touch /etc/rc.conf
sysrc sendmail_enable="NO"

# Install packages
pkg install -y postfix 
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
/usr/local/etc/rc.d postfix stop || true

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
while getopts h:n:d:b: option
do
    case \"\${option}\"
    in
      h) HOSTNAME=\${OPTARG};;
      n) MYNETWORKS=\${OPTARG};;
      d) RELAYDOMAINS=\${OPTARG};;
      b) SMTPDBANNER=\${OPTARG};;
    esac
done

# Check config variables are set
if [ -z \${MYNETWORKS+x} ]; 
then 
    echo 'MYNETWORKS is unset - setting it to 192.168.0.0/16,10.0.0.0/8' >> /var/log/cook.log
    echo 'MYNETWORKS is unset - setting it to 192.168.0.0/16,10.0.0.0/8'
    MYNETWORKS=\"192.168.0.0/16,10.0.0.0/8\" 
fi
if [ -z \${RELAYDOMAINS+x} ];
then
    echo 'RELAYDOMAINS is unset - see documentation how to configure this flavour' >> /var/log/cook.log
    echo 'RELAYDOMAINS is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${SMTPDBANNER+x} ];
then
    echo 'SMTPDBANNER is unset - setting it to \"\\\$myhostname ESMTP \\\$mail_name (\\\$mail_version)\"' >> /var/log/cook.log
    echo 'SMTPDBANNER is unset - setting it to \"\\\$myhostname ESMTP \\\$mail_name (\\\$mail_version)\"'
    SMTPDBANNER=\"\\\$myhostname ESMTP \\\$mail_name (\\\$mail_version)\" 
fi
if [ -z \${HOSTNAME+x} ];
then
    echo 'HOSTNAME is unset - setting it to \"backupmx\"' >> /var/log/cook.log
    echo 'HOSTNAME is unset - setting it to \"backupmx\"'
    HOSTNAME=\"backupmx\" 
fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE ADJUSTED & COPIED:

# main.cf 
[ -w /root/main.cf ] && sed -i '' \"s&\\\$MYNETWORKS&\$MYNETWORKS&\" /root/main.cf 
[ -w /root/main.cf ] && sed -i '' \"s/\\\$RELAYDOMAINS/\$RELAYDOMAINS/\" /root/main.cf
[ -w /root/main.cf ] && sed -i '' \"s/\\\$SMTPDBANNER/\$SMTPDBANNER/\" /root/main.cf
[ -w /root/main.cf ] && sed -i '' \"s/\\\$HOSTNAME/\$HOSTNAME/\" /root/main.cf

mkdir -p /usr/local/etc/postfix
mv /root/main.cf /usr/local/etc/postfix

mkdir -p /usr/local/etc/mail
install -m 0644 /usr/local/share/postfix/mailer.conf.postfix /usr/local/etc/mail/mailer.conf

[ -w /etc/syslog.conf ] && sed -i '' \"s/# mail.info/mail.info/\" /etc/syslog.conf

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

sysrc postfix_enable=\"YES\"
/usr/local/etc/rc.d/postfix restart
/etc/rc.d/syslogd restart

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

