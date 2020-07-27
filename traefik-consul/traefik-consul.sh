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
/usr/local/etc/rc.d/traefik stop  || true
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
if [ -z \${CONSULS
    keyFile = \\\"/usr/local/etc/ssl/cert.key\\\"

logLevel=\\\"INFO\\\"
[traefikLog]
  filePath = \\\"/var/log/traefik.log\\\"
[accessLog]
  filePath = \\\"/var/log/traefik-access.log\\\"
[api]
  dashboard = true
[consulcatalog]
  endpoint = \\\"\$CONSULSERVER:8500\\\"
  stale = false
  exposedByDefault = true
  frontEndRule = \\\"Host:{{ .ServiceName }}\\\"\" > /usr/local/etc/traefik.toml
echo \"traefik_conf=\\\"/usr/local/etc/traefik.toml\\\"\" >> /etc/rc.conf

mkdir -p /usr/local/etc/ssl/
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /usr/local/etc/ssl/cert.key -out /usr/local/etc/ssl/cert.crt -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"
chmod 644 /usr/local/etc/ssl/cert.crt
chmod 600 /usr/local/etc/ssl/cert.key

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION
/usr/local/etc/rc.d/traefik start
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
