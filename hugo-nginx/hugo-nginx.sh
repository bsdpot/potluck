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

step "Install package git"
pkg install -y git

step "Install package nginx"
pkg install -y nginx

step "Install package gohugo"
pkg install -y gohugo

step "Install package goaccess"
pkg install -y goaccess

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
if [ -z \${IP+x} ]; then
    echo 'IP is unset - see documentation to configure this flavour for an IP address. This parameter is mandatory.'
    exit 1
fi
if [ -z \${SERVERNAME+x} ]; then
    echo 'SERVERTYPE is unset - see documentation to configure this flavour fully qualified domain name. This parameter is mandatory.'
    exit 1
fi
if [ -z \${SITENAME+x} ]; then
    echo 'SITENAME is unset - see documentation to configure this flavour with a site name for hugo. This parameter is mandatory.'
    exit 1
fi
if [ -z \${GITEMAIL+x} ]; then
    echo 'GITEMAIL is unset - see documentation to configure this flavour with a git email address. This parameter is mandatory.'
    exit 1
fi
if [ -z \${GITUSER+x} ]; then
    echo 'GITUSER is unset - see documentation to configure this flavour with a git user name. This parameter is mandatory.'
    exit 1
fi
if [ -z \${CUSTOMDIR+x} ]; then
    echo 'CUSTOMDIR is unset - will create default tmp - see documentation to configure this flavour with a custom directory inside hugo.'
    CUSTOMDIR=tmp
fi
if [ -z \${IMPORTPUBKEY+x} ]; then
    echo 'IMPORTPUBKEY is unset - see documentation to configure this flavour for adding SSH keys to authorized_keys file.'
    IMPORTPUBKEY=0
fi
if [ -z \${THEMEADJUST+x} ]; then
    echo 'THEMEADJUST is unset - defaulting to 0 - see documentation to configure this flavour for custom changes to default theme.'
    THEMEADJUST=0
fi


# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# create root ssh keys
mkdir -p /root/.ssh
/usr/bin/ssh-keygen -q -N '' -f /root/.ssh/id_rsa -t rsa
chown -R root:wheel /root/.ssh
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa

# add imported key to authorized_keys
if [ \${IMPORTPUBKEY} -eq 1 ]; then
    if [ -f /root/jenkins.pub ]; then
        echo \"Adding imported /root/jenkins.pub to /root/.ssh/authorized_keys\"
        cat /root/jenkins.pub >> /root/.ssh/authorized_keys
        chown -R root:wheel /root/.ssh
    else
        echo \"Error: no /root/jenkins.pub file found\"
    fi
fi

# setup server ssh
echo \"Manually setting up host keys\"
cd /etc/ssh
/usr/bin/ssh-keygen -A
cd ~

# configure nginx
# change variables in temp file and copy to /usr/local/nginx/nginx.conf

if [ -f /root/nginx.conf ]; then
    sed < /root/nginx.conf \
    -e \"s|%%IP%%|\${IP}|g\" \
    -e \"s|%%SERVERNAME%%|\${SERVERNAME}|g\" \
    -e \"s|%%SITENAME%%|\${SITENAME}|g\" > /usr/local/etc/nginx/nginx.conf
else
    echo \"Error: no /root/nginx.conf file to modify. This error should not happen in prebuilt pot image.\"
fi

# enable nginx
service nginx enable

# goaccess
sysrc goaccess_log=\"/var/log/nginx/access.log\"
service goaccess enable

# setup hugo
cd /mnt
/usr/local/bin/hugo new site \${SITENAME}

# this has to happen after the force create of site as was wiping this
# make some directories from input variables
mkdir -p /mnt/\${SITENAME}/\${CUSTOMDIR}/

# set permissions so jenkins user can write files from jenkins image
chmod 777 /mnt/\${SITENAME}
chmod 777 /mnt/\${SITENAME}/\${CUSTOMDIR}
chmod 777 /mnt/\${SITENAME}/content
chmod 777 /mnt/\${SITENAME}/content/blog
chmod 777 /mnt/\${SITENAME}/content/micro
chmod 777 /mnt/\${SITENAME}/static

# link in /usr/local/www/SITENAME to /root/SITENAME
ln -s /mnt/\${SITENAME}/public /usr/local/www/\${SITENAME}
chown -R www:www /mnt/\${SITENAME}

# setup git
cd /mnt/\${SITENAME}
/usr/local/bin/git init
/usr/local/bin/git config user.email \${GITEMAIL}
/usr/local/bin/git config user.name \${GITUSER}
/usr/local/bin/git submodule add https://github.com/pavel-pi/kiss-em.git themes/kiss-em
/usr/local/bin/git add -v *

# implement custom theme changes for kiss-em
if [ \${THEMEADJUST} -eq 1 ]; then

    if [ -f /root/custom_theme_default_list.html ]; then
        cp -f /root/custom_theme_default_list.html /mnt/\${SITENAME}/themes/kiss-em/layouts/_default/list.html
    else
        echo \"Cannot find /root/custom_theme_default_list.html\"
    fi

    if [ -f /root/custom_theme_blog_list.html ]; then
        cp -f /root/custom_theme_blog_list.html /mnt/\${SITENAME}/themes/kiss-em/layouts/blog/list.html
    else
        echo \"Cannot find /root/custom_theme_blog_list.html\"
    fi

    if [ -f /root/custom_theme_partial_article.html ]; then
        cp -f /root/custom_theme_partial_article.html /mnt/\${SITENAME}/themes/kiss-em/layouts/partials/article.html
    else
        echo \"Cannot find /root/custom_theme_partial_article.html\"
    fi

    if [ -f /root/custom_theme_partial_footer.html ]; then
        cp -f /root/custom_theme_partial_footer.html /mnt/\${SITENAME}/themes/kiss-em/layouts/partials/footer.html
    else
        echo \"Cannot find /root/custom_theme_partial_footer.html\"
    fi

    if [ -f /root/custom_theme_taxonomy_tag.html ]; then
        cp -f /root/custom_theme_taxonomy_tag.html /mnt/\${SITENAME}/themes/kiss-em/layouts/taxonomy/tag.html
    else
        echo \"Cannot find /root/custom_theme_taxonomy_tag.html\"
    fi

fi

# final perms check
chown -R www:www /mnt/\${SITENAME}

# add changed files
cd /mnt/\${SITENAME}
/usr/local/bin/git add -v *

# commit and push
#/usr/local/bin/git commit -m \"Changed templates via cook script\"

# start hugo
# test server
# hugo server -b http://\${IP}:1313 --bind \${IP} -D
chown -R www:www /mnt/\${SITENAME}
cd /mnt/\${SITENAME}
/usr/local/bin/hugo

# create sample pages
#/usr/local/bin/hugo new blog/sample-blog-post.md
#/usr/local/bin/hugo new micro/sample-microblog-post.md

chown -R www:www /mnt/\${SITENAME}

# set permissions again so jenkins user can write files from jenkins image
# there might be another way to do this with more security
chmod 777 /mnt/\${SITENAME}
chmod 777 /mnt/\${SITENAME}/\${CUSTOMDIR}
chmod 777 /mnt/\${SITENAME}/content
chmod 777 /mnt/\${SITENAME}/content/blog
chmod 777 /mnt/\${SITENAME}/content/micro
chmod 777 /mnt/\${SITENAME}/static

# return to /root
cd ~

#
# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

# start services
service nginx start

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
