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
pkg install -y nginx mariadb105-client postgresql13-client memcached
pkg install -y fontconfig freetype2 giflib gmp icu jbigkit jpeg-turbo
pkg install -y libargon2 libgcrypt libgd libgpg-error libxslt libzip
pkg install -y oniguruma openldap-client png tiff webp pkgconf
pkg install -y php74 php74-extensions php74-bcmath php74-bz2 php74-ctype php74-curl php74-dom php74-exif php74-fileinfo php74-filter php74-gd php74-gmp php74-iconv php74-intl php74-json php74-ldap php74-mbstring php74-opcache php74-openssl php74-pdo php74-pdo_mysql php74-pecl-APCu php74-posix php74-session php74-simplexml php74-xml php74-xmlreader php74-xmlwriter php74-xsl php74-zip php74-zlib
pkg clean -y

sysrc nginx_enable="YES"
sysrc php_fpm_enable="YES"

# Create mountpoints
mkdir /.snapshots
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
/usr/local/etc/rc.d/nginx stop
/usr/local/etc/rc.d/php-fpm stop

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
#while getopts a: option
#do
#    case \"\${option}\"
#    in
#      a) ALPHA=\${OPTARG};;
#    esac
#done

# Check config variables are set
#if [ -z \${ALPHA+x} ];
#then
#    echo 'ALPHA is unset - see documentation how to configure this flavour' >> /var/log/cook.log
#    echo 'ALPHA is unset - see documentation how to configure this flavour'
#    exit 1
#fi

# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE ADJUSTED & COPIED:

# If we do not find a Wordpress installation, we install it. If we do find something though,
# we do not install/overwrite anything as we assume that updates/modifications are happening
# from within the Wordpress web guiWordpress installation, we install it. If we do find something though,
# we do not install/overwrite anything as we assume that updates/modifications are happening
# from within the Wordpress web gui..
if [ ! -e /usr/local/www/nextcloud/status.php ]
then
    pkg install -y nextcloud-php74-21.0.2 nextcloud-twofactor_totp-php74-6.1.0 nextcloud-deck-php74-1.4.2 nextcloud-mail-php74-1.9.6 nextcloud-contacts-php74-3.5.1 nextcloud-calendar-php74-2.2.2 nextcloud-end_to_end_encryption-php74-1.7.1
fi

# Configure PHP FPM
sed -i '' \"s&\\listen = 127.0.0.1:9000&listen = /var/run/php74-fpm.sock&\" /usr/local/etc/php-fpm.d/www.conf
echo \"listen.owner = www\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"listen.group = www\" >> /usr/local/etc/php-fpm.d/www.conf
echo \"listen.mode = 0660\" >> /usr/local/etc/php-fpm.d/www.conf

# Configure PHP
cp -f /usr/local/etc/php.ini-production /usr/local/etc/php.ini
cp -f /root/99-custom.ini /usr/local/etc/php/99-custom.ini

# Fix www group memberships so it works with fuse mounted directories
pw addgroup -n newwww -g 1001
pw moduser www -u 1001 -G 80,0,1001

# Configure NGINX
cp -f /root/nginx.conf /usr/local/etc/nginx/nginx.conf

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION
killall nginx
/usr/local/etc/rc.d/php-fpm restart
/usr/local/etc/rc.d/nginx restart

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
