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
# we need latest for vault 1.7.3
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
sysrc sshd_enable="YES"

step "Create /usr/local/etc/rc.d"
mkdir -p /usr/local/etc/rc.d

# we need consul for consul agent
step "Install package consul"
pkg install -y consul

step "Install package sudo"
pkg install -y sudo

step "Install package node_exporter"
pkg install -y node_exporter

step "Install package jq"
pkg install -y jq

step "Install package jo"
pkg install -y jo

step "Install package curl"
pkg install -y curl

step "Install package openssl"
pkg install -y openssl

step "Install package syslog-ng"
pkg install -y syslog-ng

step "Install package vault"
pkg install -y vault

step "Add vault user to daemon class"
pw usermod vault -G daemon

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
# vault all
if [ -z \${DATACENTER+x} ]; then
    echo 'DATACENTER is unset - see documentation to configure this flavour with the datacenter name. This parameter is mandatory for all vault image types.'
    exit 1
fi
# vault all
if [ -z \${NODENAME+x} ];
then
    echo 'NODENAME is unset - see documentation to configure this flavour with a name for this node. This parameter is mandatory for all vault image types.'
    exit 1
fi
# vault all
if [ -z \${IP+x} ]; then
    echo 'IP is unset - see documentation to configure this flavour for an IP address. This parameter is mandatory for all vault image types.'
    exit 1
fi
# vault all
# this defaults to unseal. Other options are leader for a raft cluster leader, and cluster, for a raft cluster peer.
if [ -z \${VAULTTYPE+x} ];
then
    echo 'VAULTTYPE is unset - please set the type of instance to launch from unseal, leader, follower. This parameter is mandatory for all vault image types.'
    exit 1
fi
export \$VAULTTYPE
# vault-leader only
# ip subnet to generate temporary short-lived certificates for
if [ -z \${SFTPNETWORK+x} ] && [ \$VAULTTYPE != \"unseal\" ] && [ \$VAULTTYPE != \"follower\" ];
then
    echo 'SFTPNETWORK is unset - please provide a comma-separated list of IP addresses to pre-generate temporary TLS certificates. This parameter is mandatory for vault leader images.'
    exit 1
fi
# vault-leader and vault-follower
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen for the consul flavour.
# Re-used for nomad, which is usually 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the one from the consul flavour
if [ -z \${GOSSIPKEY+x} ]  && [ \$VAULTTYPE != \"unseal\" ];
then
    echo 'GOSSIPKEY is unset - please provide a 32 byte base64 key from the (consul keygen key) command. This parameter is mandatory for vault leader and follower image types.'
    exit 1
fi
# vault-leader and vault-follower
# IP address of the unseal server
if [ -z \${UNSEALIP+x} ] && [ \$VAULTTYPE != \"unseal\" ];
then
    echo 'UNSEALIP is unset - please provide the IP address for the vault unseal node. This parameter is mandatory for vault leader and follower image types.'
    exit 1
fi
# vault-leader and vault-follower
if [ -z \${CONSULSERVERS+x} ] && [ \$VAULTTYPE != \"unseal\" ]; then
    echo 'CONSULSERVERS is unset - please pass in one or more correctly-quoted, comma-separated addresses for consul peer IPs. Refer to documentation. This parameter is mandatory for vault leader and follower image types.'
    exit 1
fi
# vault-leader and vault-follower
# Unwrap token to pass into cluster
if [ -z \${UNSEALTOKEN+x} ] && [ \$VAULTTYPE != \"unseal\" ];
then
    echo 'UNSEALTOKEN is unset - please pass in an unseal token, or set to \"unset\" for an unseal node. This parameter is mandatory for vault leader and follower image types.'
    exit 1
fi
# vault-leader and vault-follower
# sftpuser credentials
if [ -z \${SFTPUSER+x} ] && [ \$VAULTTYPE != \"unseal\" ];
then
    echo 'SFTPUSER is unset - please provide a username to use for the SFTP user on the vault leader. This parameter is mandatory for vault leader and follower image types.'
    exit 1
fi
# vault-leader and vault-follower
# sftpuser password
if [ -z \${SFTPPASS+x} ] && [ \$VAULTTYPE != \"unseal\" ];
then
    echo 'SFTPPASS is unset - please provide a password for the SFTP user on the vault leader. This parameter is mandatory for vault leader and follower image types.'
    exit 1
fi
# vault-follower only
# Vault leader IP
if [ -z \${VAULTLEADER+x} ] && [ \$VAULTTYPE != \"unseal\" ] && [ \$VAULTTYPE != \"leader\" ];
then
    echo 'VAULTLEADER is unset - please provide the IP address for the vault leader node. This parameter is mandatory for vault follower images.'
    exit 1
fi
# vault-follower only
# Vault leader token
if [ -z \${LEADERTOKEN+x} ] && [ \$VAULTTYPE != \"unseal\" ] && [ \$VAULTTYPE != \"leader\" ];
then
    echo 'LEADERTOKEN is unset - please provide a token from the vault leader for follower nodes to use. This parameter is mandatory for vault follower images.'
    exit 1
fi
# optional
# logging to remote syslog server
if [ -z \${REMOTELOG+x} ];
then
    echo 'REMOTELOG is unset - please provide the IP address of a loki server, or set a null value. This parameter is optional for vault leader and follower image types.'
    REMOTELOG=\"null\"
fi


# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# add group for accessing certs (shared between services)
pw groupadd certaccess

# setup directories for vault usage
mkdir -p /mnt/templates
mkdir -p /mnt/certs/hash
chgrp -R certaccess /mnt/certs
mkdir -p /mnt/vault

## start Vault

# first remove any existing vault configuration
if [ -f /usr/local/etc/vault/vault-server.hcl ]; then
    rm /usr/local/etc/vault/vault-server.hcl
fi
# then setup a fresh vault.hcl specific to the type of image

# default FreeBSD vault.hcl is /usr/local/etc/vault.hcl and
# the init script /usr/local/etc/rc.d/vault refers to this
# but many vault docs refer to /usr/local/etc/vault/vault-server.hcl
# or similar

# Create vault configuration file
# Three types of vault servers
# - unseal (unseal node)
# - leader (raft cluster leader)
# - cluster (raft cluster member)

case \$VAULTTYPE in

  ### Vault type: Unseal Node - no consul or node_template setup
  unseal)
    export VAULT_CLIENT_TIMEOUT=300s

    #begin vault config
    echo \"disable_mlock = true
ui = true
# enable when vnet interface in use by pot
#listener \\\"tcp\\\" {
#  address = \\\"127.0.0.1:8200\\\"
#  tls_disable = 1
#}
listener \\\"tcp\\\" {
  address = \\\"\$IP:8200\\\"
  tls_disable = 1
  telemetry {
    unauthenticated_metrics_access = true
  }
}
# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
# if using another directory update this path accordingly
storage \\\"file\\\" {
  path    = \\\"/mnt/vault/\\\"
}
log_level = \\\"Debug\\\"
api_addr = \\\"http://\$IP:8200\\\"
\" > /usr/local/etc/vault.hcl

    # setup autounseal config
    echo \"path \\\"transit/encrypt/autounseal\\\" {
  capabilities = [ \\\"update\\\" ]
}
path \\\"transit/decrypt/autounseal\\\" {
  capabilities = [ \\\"update\\\" ]
}
\" > /root/autounseal.hcl

    # set permissions on /mnt for vault data
    chown -R vault:wheel /mnt/templates
    chown -R vault:wheel /mnt/vault

    # invite to certaccess group
    /usr/sbin/pw usermod vault -G certaccess

    # remove the copied in rotate-certs.sh file, not needed on unseal node
    if [ -f /root/rotate-certs.sh ]; then
        rm -f /root/rotate-certs.sh
    fi

    # setup rc.conf entries
    # we do not set vault_user=vault because vault will not start
    service vault enable
    sysrc vault_login_class=root
    sysrc vault_syslog_output_enable=\"YES\"
    sysrc vault_syslog_output_priority=\"warn\"

    # setup some automation scripts
    echo \"#!/bin/sh
/usr/local/bin/vault audit enable -address=http://\$IP:8200 file file_path=/mnt/audit.log
/usr/local/bin/vault secrets enable -address=http://\$IP:8200 transit
/usr/local/bin/vault write -address=http://\$IP:8200 -f transit/keys/autounseal
/usr/local/bin/vault policy write -address=http://\$IP:8200 autounseal /root/autounseal.hcl
\" > /root/setup-autounseal.sh

    chmod +x /root/setup-autounseal.sh

    # setup quick way to issue unseal tokens
    echo \"#!/bin/sh
/usr/local/bin/vault token create -address=http://\$IP:8200 -policy=\\\"autounseal\\\" -wrap-ttl=24h
\" > /root/issue-unseal.sh

    chmod +x /root/issue-unseal.sh

    # setup a quick way to check vault status
    echo \"#!/bin/sh
/usr/local/bin/vault status -address=http://\$IP:8200
\" > /root/vault-status.sh

    chmod +x /root/vault-status.sh

    # start vault
    echo \"Starting Vault Unseal Node\"
    /usr/local/etc/rc.d/vault start

    echo \"------------------------------------------------------------------------------------------\"
    echo \"Unseal node is almost complete, you must now login and manually run the following\"
    echo \"commands to complete the setup:\"
    echo \" \"
    echo \"  vault operator init -address=http://\$IP:8200\"
    echo \"  vault operator unseal -address=http://\$IP:8200\"
    echo \"     (paste key1)\"
    echo \"  vault operator unseal -address=http://\$IP:8200\"
    echo \"     (paste key2)\"
    echo \"  vault operator unseal -address=http://\$IP:8200\"
    echo \"     (paste key3)\"
    echo \"  vault login -address=http://\$IP:8200\"
    echo \"     (use token from operator init)\"
    echo \" \"
    echo \" Then run /root/setup-autounseal.sh to automatically run each of the following 4 steps \"
    echo \"  vault audit enable -address=http://\$IP:8200 file file_path=/mnt/audit.log\"
    echo \"  vault secrets enable -address=http://\$IP:8200 transit\"
    echo \"  vault write -address=http://\$IP:8200 -f transit/keys/autounseal\"
    echo \"  vault policy write -address=http://\$IP:8200 autounseal /root/autounseal.hcl\"
    echo \" \"
    echo \"Unseal node is setup\"
    echo \" \"
    echo \"To issue unseal tokens for each RAFT cluster node, run /root/issue-unseal.sh or manually run:\"
    echo \" \"
    echo \"  vault token create -address=http://\$IP:8200 -policy=\\\"autounseal\\\" -wrap-ttl=24h\"
    echo \" \"
    echo \"You must run this for each node in your cluster. Every node needs an unseal token.\"
    echo \"------------------------------------------------------------------------------------------\"
    # end unseal config
    ;;

    ### Vault type: RAFT Leader
    leader)

    export VAULT_CLIENT_TIMEOUT=300s
    export VAULT_MAX_RETRIES=5

    # setup chroot directory for use by sftp, gets wiped on reboot
    mkdir -p /tmpcerts
    chown root:wheel /tmpcerts
    chmod 755 /tmpcerts

    # begin sftpuser configuration
    echo \"Setting up ssh and sftp\"
    echo \"Port 8888
PubkeyAuthentication yes
AuthorizedKeysFile       .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
StrictModes no
UseDNS no
Banner none
#LogLevel DEBUG
AllowAgentForwarding yes
PermitTTY yes
AllowUsers \$SFTPUSER

Match User \$SFTPUSER
  ChrootDirectory /tmpcerts
  X11Forwarding no
  AllowTcpForwarding no
  ForceCommand internal-sftp
\" >> /etc/ssh/sshd_config

    # setup host keys
    echo \"Manually setting up host keys\"
    cd /etc/ssh
    /usr/bin/ssh-keygen -A
    cd /

    # setup a user
    /usr/sbin/pw useradd -n \$SFTPUSER -c 'certificate user' -m -s /bin/sh -h 0 <<EOP
\$SFTPPASS
EOP

    # setup user ssh key to be exported for use elsewhere
    echo \"Setting up \$SFTPUSER ssh keys\"
    mkdir -p /home/\$SFTPUSER/.ssh
    /usr/bin/ssh-keygen -q -N '' -f /home/\$SFTPUSER/.ssh/id_rsa -t rsa
    chmod 700 /home/\$SFTPUSER/.ssh
    cat /home/\$SFTPUSER/.ssh/id_rsa.pub > /home/\$SFTPUSER/.ssh/authorized_keys
    chmod 700 /home/\$SFTPUSER/.ssh
    chmod 600 /home/\$SFTPUSER/.ssh/id_rsa
    chmod 644 /home/\$SFTPUSER/.ssh/authorized_keys
    chown \$SFTPUSER:\$SFTPUSER /home/\$SFTPUSER/.ssh

    echo \"\"
    echo \"########################### IMPORTANT NOTICE ###########################\"
    echo \"\"
    echo \"You must copy /home/\$SFTPUSER/.ssh/id_rsa OUT of this vault image, and\"
    echo \"then copy IN to all other images' (to /root/.ssh/id_rsa) which need to\"
    echo \"login to vault and get certificates issued!\"
    echo \"\"
    echo \"This is required so that tls-client-validation is always enforced.\"
    echo \"Round 1: temp certificates for vault leader login tls-client-validation\"
    echo \"Round 2: get certificates from vault for vault agent and applications\"
    echo \"\"
    echo \"########################################################################\"
    echo \"\"

    # restart ssh
    echo \"Restarting ssh\"
    /etc/rc.d/sshd restart

    # begin vault config
    echo \"disable_mlock = true
ui = true
# enable when vnet interface in use by pot
#listener \\\"tcp\\\" {
#  address = \\\"127.0.0.1:8200\\\"
#  tls_disable = 1
#}
listener \\\"tcp\\\" {
  address = \\\"\$IP:8200\\\"
  cluster_address = \\\"\$IP:8201\\\"
  telemetry {
    unauthenticated_metrics_access = true
  }
  # set to zero to enable TLS only
  tls_disable = 1
  #xyz#tls_skip_verify = false
  #xyz#tls_require_and_verify_client_cert = true
  #xyz#tls_client_ca_file = \\\"/mnt/certs/ca.pem\\\"
  #xyz#tls_cert_file = \\\"/mnt/certs/cert.pem\\\"
  #xyz#tls_key_file = \\\"/mnt/certs/key.pem\\\"
}
# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
# if using another directory update this path accordingly
storage \\\"raft\\\" {
  path    = \\\"/mnt/vault/\\\"
  node_id = \\\"\$NODENAME\\\"
  autopilot_reconcile_interval = \\\"5s\\\"
  retry_join {
    leader_api_addr = \\\"http://\$IP:8200\\\"
    #xyz#leader_ca_cert_file = \\\"/mnt/certs/ca.pem\\\"
    #xyz#leader_client_cert_file = \\\"/mnt/certs/cert.pem\\\"
    #xyz#leader_client_key_file = \\\"/mnt/certs/key.pem\\\"
  }
}
seal \\\"transit\\\" {
  address = \\\"http://\$UNSEALIP:8200\\\"
  disable_renewal = \\\"false\\\"
  key_name = \\\"autounseal\\\"
  mount_path = \\\"transit/\\\"
  token = \\\"UNWRAPPEDTOKEN\\\"
}
telemetry {
  disable_hostname = true
  prometheus_retention_time = \\\"24h\\\"
}
#brb#service_registration \\\"consul\\\" {
#brb#  address = \\\"\$IP:8500\\\"
#brb#  scheme = \\\"http\\\"
#brb#  service = \\\"vault\\\"
#brb#  tls_ca_file = \\\"/mnt/certs/combinedca.pem\\\"
#brb#  tls_cert_file = \\\"/mnt/certs/cert.pem\\\"
#brb#  tls_key_file = \\\"/mnt/certs/key.pem\\\"
#brb#}
pid_file = \\\"/var/run/vault.pid\\\"
log_format = \\\"standard\\\"
log_level = \\\"Debug\\\"
api_addr = \\\"http://\$IP:8200\\\"
cluster_addr = \\\"http://\$IP:8201\\\"
\" | (umask 177; cat > /usr/local/etc/vault.hcl)

    # Set permission for vault.hcl, so that vault can read it
    chown vault:wheel /usr/local/etc/vault.hcl

    # set permissions on /mnt for vault data
    chown -R vault:wheel /mnt/vault

    # invite to certaccess group
    /usr/sbin/pw usermod vault -G certaccess

    # setup rc.conf entries
    # we do not set vault_user=vault because vault will not start
    service vault enable
    sysrc vault_login_class=root
    sysrc vault_syslog_output_enable=\"YES\"
    sysrc vault_syslog_output_priority=\"warn\"

    # set vault timeout
    export VAULT_CLIENT_TIMEOUT=300s

    # if we need to autounseal with passed in unwrap token
    # vault unwrap [options] [TOKEN]
    (umask 177; /usr/local/bin/vault unwrap -address=http://\$UNSEALIP:8200 -format=json \$UNSEALTOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/unwrapped.token)
    if [ -s /root/unwrapped.token ]; then
        THIS_TOKEN=\$(/bin/cat /root/unwrapped.token)
        (umask 177; /usr/bin/sed -i .orig \"/UNWRAPPEDTOKEN/s/UNWRAPPEDTOKEN/\$THIS_TOKEN/g\" /usr/local/etc/vault.hcl)
    fi

    # start vault
    echo \"Starting Vault Leader\"
    service vault start

    # login
    echo \"Logging in to unseal vault\"
    for i in \$(jot 30); do
      echo \"login round: \$i\"
      (umask 177; /usr/local/bin/vault login -address=http://\$UNSEALIP:8200 -format=json \$THIS_TOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/this.token)
      if [ \$? -eq 0 ]; then
        break
      fi
      sleep 2
    done

    # perform operator init on unsealed node and get recovery keys instead of unseal keys, save to file
    (umask 177; /usr/local/bin/vault operator init -address=http://\$IP:8200 -format=json > /root/recovery.keys)

    # set some variables from the saved file
    # the saved file may be a security risk?
    echo \"Setting variables from recovery.keys\"
    KEY1=\$(/bin/cat /root/recovery.keys | /usr/local/bin/jq -r '.recovery_keys_b64[0]')
    KEY2=\$(/bin/cat /root/recovery.keys | /usr/local/bin/jq -r '.recovery_keys_b64[1]')
    KEY3=\$(/bin/cat /root/recovery.keys | /usr/local/bin/jq -r '.recovery_keys_b64[2]')
    KEY4=\$(/bin/cat /root/recovery.keys | /usr/local/bin/jq -r '.recovery_keys_b64[3]')
    KEY5=\$(/bin/cat /root/recovery.keys | /usr/local/bin/jq -r '.recovery_keys_b64[4]')
    ROOTKEY=\$(/bin/cat /root/recovery.keys | /usr/local/bin/jq -r '.root_token')

    echo \"Unsealing raft cluster\"
    /usr/local/bin/vault operator unseal -address=http://\$IP:8200 \$KEY1
    /usr/local/bin/vault operator unseal -address=http://\$IP:8200 \$KEY2
    /usr/local/bin/vault operator unseal -address=http://\$IP:8200 \$KEY3
    # uncomment this if more than 3 keys required to unseal
    #/usr/local/bin/vault operator unseal -address=http://\$IP:8200 \$KEY4
    #/usr/local/bin/vault operator unseal -address=http://\$IP:8200 \$KEY5

    echo \"Please wait for cluster...\"
    for i in \$(jot 10); do
      echo \"round: \$i\"
      /usr/local/bin/vault status -address=http://\$UNSEALIP:8200
      if [ \$? -eq 0 ]; then
        break
      fi
      sleep 1
    done

    # The vault documentation says this is not done on first node, but raft only works if it is!
    echo \"Joining the raft cluster\"
    /usr/local/bin/vault operator raft join -address=http://\$IP:8200

    echo \"Logging in to local raft instance\"
    for i in \$(jot 30); do
      echo \"login round: \$i\"
      (umask 177; echo \"\$ROOTKEY\" | /usr/local/bin/vault login -address=http://\$IP:8200 -method=token -field=token token=- > /root/login.token)
      if [ \$? -eq 0 ]; then
        break
      fi
      sleep 2
    done

    if [ -s /root/login.token ]; then
        TOKENOUT=\$(/bin/cat /root/login.token)
        echo \"Your new login token is \$TOKENOUT\"
        echo \"Also available in /root/login.token\"

        # setup logging
        echo \"enabling /mnt/vault/audit.log\"
        /usr/local/bin/vault audit enable -address=http://\$IP:8200 file file_path=/mnt/vault/audit.log

        # enable pki and become a CA
        echo \"Setting up raft cluster CA\"
        echo \"\"
        # tweak raft autopilot settings
        # requires vault 1.7
        /usr/local/bin/vault operator raft autopilot set-config -address=http://\$IP:8200 -dead-server-last-contact-threshold=10s -server-stabilization-time=30s -cleanup-dead-servers=true -min-quorum=3

        # vault secrets enable [options] TYPE
        # enable the pki secrets engine at the pki path
        echo \"Enabling PKI\"
        /usr/local/bin/vault secrets enable -address=http://\$IP:8200 pki

        # vault secrets tune [options] PATH
        # Tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL) of 87600 hours (10 years)
        echo \"Tuning PKI\"
        /usr/local/bin/vault secrets tune -max-lease-ttl=87600h -address=http://\$IP:8200 pki/

        # enable cert authentication, currently disabled
        echo \"Enabling certificate authentication\"
        /usr/local/bin/vault auth enable -address=http://\$IP:8200 cert

        # vault write [options] PATH [DATA K=V...]
        # Generate the root CA, extracting the root CA certificate to CA_cert.pem in pem format
        # note: the secret key is not exported
        echo \"Generating internal certificate\"
        /usr/local/bin/vault write -address=http://\$IP:8200 -field=certificate pki/root/generate/internal common_name=\"\$DATACENTER\" ttl=\"87600h\" format=pem exclude_cn_from_sans=true > /mnt/certs/CA_cert.pem
        # we need this newline for combining certs later
        echo \"\" >> /mnt/certs/CA_cert.pem
        # configure the CA and CRL endpoints
        echo \"Writing certificate URLs\"
        /usr/local/bin/vault write -address=http://\$IP:8200 pki/config/urls issuing_certificates=\"http://\$IP:8200/v1/pki/ca\" crl_distribution_points=\"http://\$IP:8200/v1/pki/crl\"

        # setup intermediate CA
        echo \"Setting up raft cluster intermediate CA\"
        # vault secrets enable [options] TYPE
        # enable the pki secrets engine at the pki_int path
        echo \"Enabling PKI Intermediate\"
        /usr/local/bin/vault secrets enable -address=http://\$IP:8200 -path=pki_int pki

        # vault secrets tune [options] PATH
        # tune the secrets engine to issue certificates with a maximum time-to-live (TTL) of 43800 hours (5 years)
        echo \"Tuning PKI Intermediate\"
        /usr/local/bin/vault secrets tune -max-lease-ttl=43800h -address=http://\$IP:8200 pki_int/

        # vault write [options] PATH [DATA K=V...]
        # generate an intermediate certificate and save the CSR
        echo \"Writing intermediate certificate to file\"
        (umask 177; /usr/local/bin/vault write -address=http://\$IP:8200 -format=json pki_int/intermediate/generate/exported common_name=\"\$DATACENTER Intermediate Authority\" format=pem exclude_cn_from_sans=true > /mnt/certs/pki_intermediate.json)
        # Extract the private key & certificate signing request from the previous command
        (umask 177; /usr/local/bin/jq -r '.data.private_key' < /mnt/certs/pki_intermediate.json > /mnt/certs/intermediate.key.pem)
        /usr/local/bin/jq -r '.data.csr' < /mnt/certs/pki_intermediate.json > /mnt/certs/pki_intermediate.csr

        # Sign the intermediate certificate with the root certificate and save the generated certificate as intermediate.cert.pem
        echo \"Signing intermediate certificate\"
        /usr/local/bin/vault write -address=http://\$IP:8200 -format=json pki/root/sign-intermediate csr=@/mnt/certs/pki_intermediate.csr format=pem_bundle ttl=\"43800h\" | /usr/local/bin/jq -r '.data.certificate' > /mnt/certs/intermediate.cert.pem

        # once CSR signed and root CA returns certificate, import back into vault
        echo \"Storing intermediate certificate\"
        /usr/local/bin/vault write -address=http://\$IP:8200 pki_int/intermediate/set-signed certificate=@/mnt/certs/intermediate.cert.pem

        # combine intermediate certs and root CA into chain
        cat /mnt/certs/intermediate.cert.pem > /mnt/certs/intermediate.chain.pem
        cat /mnt/certs/CA_cert.pem >> /mnt/certs/intermediate.chain.pem

        # setup roles
        echo \"Setting up roles\"
        # vault write [options] PATH [DATA K=V...]
        # setup roles to enable certificate issue
        /usr/local/bin/vault write -address=http://\$IP:8200 pki_int/roles/\$DATACENTER allow_any_name=true allow_bare_domains=true allow_subdomains=true max_ttl=\"720h\" require_cn=false generate_lease=true allow_ip_sans=true allow_localhost=true enforce_hostnames=false 
        /usr/local/bin/vault write -address=http://\$IP:8200 pki_int/issue/\$DATACENTER common_name=\"\$DATACENTER\" ttl=\"24h\"
        /usr/local/bin/vault write -address=http://\$IP:8200 pki/roles/\$DATACENTER allow_any_name=true allow_bare_domains=true allow_subdomains=true max_ttl=\"72h\" require_cn=false allow_ip_sans=true allow_localhost=true enforce_hostnames=false 

        # set policy in a file, will import next
        # this needs a review, from multiple sources
        echo \"Writing detailed vault policy to file /root/vault.policy\"
        echo \"
path \\\"sys/mounts/*\\\" { capabilities = [ \\\"create\\\", \\\"read\\\", \\\"update\\\", \\\"delete\\\", \\\"list\\\"] }
path \\\"sys/mounts\\\" { capabilities = [ \\\"read\\\", \\\"list\\\"] }
path \\\"auth/token/roles/\$DATACENTER\\\" { capabilities = [ \\\"read\\\", \\\"update\\\"] }
path \\\"auth/token/revoke-accessor\\\" { capabilities = [ \\\"update\\\"] }
path \\\"auth/token/create/*\\\" { capabilities = [ \\\"update\\\"] }
path \\\"pki/cert/ca\\\" { capabilities = [\\\"read\\\"] }
path \\\"pki*\\\" { capabilities = [\\\"read\\\", \\\"list\\\", \\\"update\\\", \\\"delete\\\", \\\"list\\\", \\\"sudo\\\"] }
path \\\"pki/roles/\$DATACENTER\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki/sign/\$DATACENTER\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki_int/roles/\$DATACENTER\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki_int/sign/\$DATACENTER\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki_int/issue/*\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki_int/certs/\\\" { capabilities = [\\\"list\\\"] }
path \\\"pki_int/revoke\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki_int/tidy\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
\" > /root/vault.policy

        echo \"Writing vault policy to Vault\"
        # vault policy write [options] NAME PATH
        /usr/local/bin/vault policy write -address=http://\$IP:8200 pki /root/vault.policy

        # setup role
        /usr/local/bin/vault write -address=http://\$IP:8200 auth/token/roles/\$DATACENTER allowed_policies=\"pki\" orphan=true period=\"24h\"
    fi

    # setup template files for certificates
    # this is not currently in use, using cron job to rotate certs
    # it also doesn't hash the ca.pem file, which cron job does
    echo \"{{- /* /mnt/templates/cert.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$IP\\\" \\\"ttl=24h\\\" \\\"alt_names=\$NODENAME\\\" \\\"ip_sans=\$IP\\\" }}
{{ .Data.certificate }}{{ end }}
\" > /mnt/templates/cert.tpl

    echo \"{{- /* /mnt/templates/ca.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$IP\\\" }}
{{ .Data.issuing_ca }}{{ end }}
\" > /mnt/templates/ca.tpl

    echo \"{{- /* /mnt/templates/key.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$IP\\\" \\\"ttl=24h\\\" \\\"alt_names=\$NODENAME\\\" \\\"ip_sans=\$IP\\\" }}
{{ .Data.private_key }}{{ end }}
\" > /mnt/templates/key.tpl

# removed as not using vault to renew currently
#    # update vault.hcl
#    echo \"template {
#  source = \\\"/mnt/templates/cert.tpl\\\"
#  destination = \\\"/mnt/certs/cert.pem\\\"
#}
#template {
#  source = \\\"/mnt/templates/ca.tpl\\\"
#  destination = \\\"/mnt/certs/ca.pem\\\"
#}
#template {
#  source = \\\"/mnt/templates/key.tpl\\\"
#  destination = \\\"/mnt/certs/key.pem\\\"
#}
#\" >> /usr/local/etc/vault.hcl

    # new payload approach, using jo to generate json
    /usr/local/bin/jo -p common_name=\$IP alt_names=\$NODENAME ttl=24h ip_sans=\"\$IP,127.0.0.1\" format=pem > /mnt/templates/payload.json

    # generate certificates to use
    # we use curl to get the certificates in json format as the issue command only has formats: pem, pem_bundle, der
    # but no json format except via the API
    if [ -s /root/login.token ]; then
        HEADER=\$(/bin/cat /root/login.token)
        for i in \$(jot 30); do
          echo \"issue round: \$i\"
          (umask 177; /usr/local/bin/curl -f --header \"X-Vault-Token: \$HEADER\" --request POST --data @/mnt/templates/payload.json http://\$IP:8200/v1/pki_int/issue/\$DATACENTER > /mnt/certs/vaultissue.json)
          if [ \$? -eq 0 ]; then
            break
          fi
          sleep 2
        done

        # extract the required certificates to individual files
        /usr/local/bin/jq -r '.data.certificate' /mnt/certs/vaultissue.json > /mnt/certs/cert.pem
        /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json >> /mnt/certs/cert.pem
        (umask 137; /usr/local/bin/jq -r '.data.private_key' /mnt/certs/vaultissue.json > /mnt/certs/key.pem)
        /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json > /mnt/certs/ca.pem

        cd /mnt/certs
        # concat the root CA and intermediary CA into combined file
        cat CA_cert.pem ca.pem > combinedca.pem
        # steps here to hash ca
        ln -s ca.pem hash/\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/ca.pem).0
        ln -s combinedca.pem hash/\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/combinedca.pem).0
        cd /root
        # set permissions on /mnt/certs for vault
        chown -R vault:certaccess /mnt/certs
        # validate the certificates
        echo \"Validating client certificate\"
        if [ -s /mnt/certs/combinedca.pem ] && [ -s /mnt/certs/cert.pem ]; then
            /usr/bin/openssl verify -CAfile /mnt/certs/combinedca.pem /mnt/certs/cert.pem
        fi
    fi

    # if we get a successful private key, update vault.hcl and restart vault
    if [ -s /mnt/certs/key.pem ]; then
        (umask 177; /usr/bin/sed -i .orig 's/tls_disable = 1/tls_disable = 0/g' /usr/local/etc/vault.hcl)

        # update http to https, this will include leader_api_addr
        (umask 177; /usr/bin/sed -i .orig '/api_addr/s/http/https/' /usr/local/etc/vault.hcl)
        (umask 177; /usr/bin/sed -i .orig '/cluster_addr/s/http/https/' /usr/local/etc/vault.hcl)

        # remove the comment #xyz# to enable certificates
        (umask 177; /usr/bin/sed -i .orig 's/#xyz#tls/tls/g' /usr/local/etc/vault.hcl)
        (umask 177; /usr/bin/sed -i .orig 's/#xyz#leader/leader/g' /usr/local/etc/vault.hcl)

        # enable consul components
        (umask 177; /usr/bin/sed -i .orig 's/#brb#//g' /usr/local/etc/vault.hcl)

        # optional remote logging
        if [ ! -z \$REMOTELOG ] && [ \$REMOTELOG != \"null\" ]; then
            if [ -f /root/syslog-ng.conf ]; then
                /usr/bin/sed -i .orig \"s/REMOTELOGIP/\$REMOTELOG/g\" /root/syslog-ng.conf
                cp -f /root/syslog-ng.conf /usr/local/etc/syslog-ng.conf
                # stop syslogd
                service syslogd onestop || true
                # setup sysrc entries to start and set parameters to accept logs from remote subnet
                sysrc syslogd_enable=\"NO\"
                sysrc syslog_ng_enable=\"YES\"
                #sysrc syslog_ng_flags=\"-u daemon\"
                sysrc syslog_ng_flags=\"-R /tmp/syslog-ng.persist\"
                /usr/local/etc/rc.d/syslog-ng start
                echo \"syslog-ng setup complete\"
            else
                echo \"/root/syslog-ng.conf is missing?\"
            fi
        else
            echo \"REMOTELOG parameter is not set to an IP address. syslog-ng won't operate.\"
        fi

        ## start consul config
        # make consul configuration directory and set permissions
        mkdir -p /usr/local/etc/consul.d
        chown consul /usr/local/etc/consul.d
        chmod 750 /usr/local/etc/consul.d

        # Create the consul agent config file with imported variables
        echo \"{
\\\"advertise_addr\\\": \\\"\$IP\\\",
\\\"datacenter\\\": \\\"\$DATACENTER\\\",
\\\"node_name\\\": \\\"\$NODENAME\\\",
\\\"data_dir\\\":  \\\"/var/db/consul\\\",
\\\"dns_config\\\": {
  \\\"a_record_limit\\\": 3,
  \\\"enable_truncate\\\": true
},
\\\"verify_incoming\\\": true,
\\\"verify_outgoing\\\": true,
\\\"verify_server_hostname\\\": false,
\\\"verify_incoming_rpc\\\":true,
\\\"ca_file\\\": \\\"/mnt/certs/combinedca.pem\\\",
\\\"cert_file\\\": \\\"/mnt/certs/cert.pem\\\",
\\\"key_file\\\": \\\"/mnt/certs/key.pem\\\",
\\\"log_file\\\": \\\"/var/log/consul/\\\",
\\\"log_level\\\": \\\"WARN\\\",
\\\"encrypt\\\": \\\"\$GOSSIPKEY\\\",
\\\"start_join\\\": [ \$CONSULSERVERS ],
\\\"service\\\": {
  \\\"name\\\": \\\"node-exporter\\\",
  \\\"tags\\\": [\\\"_app=vault\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\"],
  \\\"port\\\": 9100
}
}\" | (umask 177; cat > /usr/local/etc/consul.d/agent.json)

        # set owner and perms on agent.json
        chown consul:wheel /usr/local/etc/consul.d/agent.json
        chmod 640 /usr/local/etc/consul.d/agent.json

        # enable consul
        service consul enable

        # set load parameter for consul config
        sysrc consul_args=\"-config-file=/usr/local/etc/consul.d/agent.json\"
        #sysrc consul_datadir=\"/var/db/consul\"

        # setup consul logs, might be redundant if not specified in agent.json above
        mkdir -p /var/log/consul
        touch /var/log/consul/consul.log
        chown -R consul:wheel /var/log/consul

        # add the consul user to the wheel group, this seems to be required for
        # consul to start on this instance. May need to figure out why.
        # I'm not entirely sure this is the correct way to do it
        /usr/sbin/pw usermod consul -G certaccess

        ## end consul

        # start consul agent
        service consul start

        # node exporter needs tls setup
        echo \"tls_server_config:
  cert_file: /mnt/certs/cert.pem
  key_file: /mnt/certs/key.pem
\" > /usr/local/etc/node-exporter.yml

        # add node_exporter user
        /usr/sbin/pw useradd -n nodeexport -c 'nodeexporter user' -m -s /usr/bin/nologin -h -

        # invite node_exporter to certaccess group
        /usr/sbin/pw usermod nodeexport -G certaccess

        # enable node_exporter service
        service node_exporter enable
        sysrc node_exporter_args=\"--web.config=/usr/local/etc/node-exporter.yml\"
        sysrc node_exporter_user=nodeexport
        sysrc node_exporter_group=nodeexport

        # start node_exporter
        service node_exporter start

        # restart vault, requires SIGHUP
        echo \"We must restart vault to enable https\"
        service vault restart
    fi

    # get list of secrets engines (helps cluster to align)
    /usr/local/bin/vault secrets list -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem

    # setup temp certs for client first login
    # destination is /tmpcerts/\$IP/cert.pem | /tmpcerts/\$IP/key.pem | | /tmpcerts/\$IP/cat.pem
    echo \"\"
    echo \"Building SFTPNETWORK list\"
    echo \"\"

    # You would pass in the IP addresses to generate certificates for as a comma separated list of IPs
    # turn comma_space into newline
    COMMATONEWLINE=\$(echo \$SFTPNETWORK |sed 's/, /\n/g')
    # diagnostics
    echo \$COMMATONEWLINE > /tmpcerts/iplist.txt

    # generate certificates per host
    for sftphost in \$COMMATONEWLINE; do
        mkdir -p /tmpcerts/\$sftphost
        # use jo to generate payload.json file
        /usr/local/bin/jo -p common_name=\$sftphost ttl=2h ip_sans=\"\$sftphost,127.0.0.1\" format=pem > /tmpcerts/\$sftphost/payload.json
        if [ -s /root/login.token ]; then
            echo \"Generating 2 hour ttl client cert for ip \$sftphost in /tmpcerts/\$sftphost/...\"
            HEADER=\$(/bin/cat /root/login.token)
            for i in \$(jot 30); do
              echo \"issue round: \$i\"
              (umask 177; /usr/local/bin/curl -f --silent --cacert /mnt/certs/ca.pem --cert /mnt/certs/cert.pem --key /mnt/certs/key.pem --header \"X-Vault-Token: \$HEADER\" --request POST --data @/tmpcerts/\$sftphost/payload.json https://\$IP:8200/v1/pki_int/issue/\$DATACENTER > /tmpcerts/\$sftphost/vaultissue.json)
              if [ \$? -eq 0 ]; then
                break
              fi
              sleep 2
            done
            # extract the required certificates to individual files
            /usr/local/bin/jq -r '.data.certificate' /tmpcerts/\$sftphost/vaultissue.json > /tmpcerts/\$sftphost/cert.pem
            /usr/local/bin/jq -r '.data.issuing_ca' /tmpcerts/\$sftphost/vaultissue.json >> /tmpcerts/\$sftphost/cert.pem
            (umask 177; /usr/local/bin/jq -r '.data.private_key' /tmpcerts/\$sftphost/vaultissue.json > /tmpcerts/\$sftphost/key.pem)
            /usr/local/bin/jq -r '.data.issuing_ca' /tmpcerts/\$sftphost/vaultissue.json > /tmpcerts/\$sftphost/ca.pem
            # concat the root CA and intermediary CA into combined file
            cat /mnt/certs/CA_cert.pem /tmpcerts/\$sftphost/ca.pem > /tmpcerts/\$sftphost/combinedca.pem
            chown -R \$SFTPUSER:wheel /tmpcerts/\$sftphost/
            # validate the certificates
            echo \"Validating client certificate\"
            if [ -s /tmpcerts/\$sftphost/combinedca.pem ] && [ -s /tmpcerts/\$sftphost/cert.pem ]; then
                /usr/bin/openssl verify -CAfile /tmpcerts/\$sftphost/combinedca.pem /tmpcerts/\$sftphost/cert.pem
            fi
        fi
    done

    echo \"Creating auto-login script\"
    # setup auto-login script
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
# redundant as also using in command line
export VAULT_CLIENT_CERT=/mnt/certs/cert.pem
export VAULT_CLIENT_KEY=/mnt/certs/key.pem
if [ -s /root/login.token ]; then
    /bin/cat /root/login.token | /usr/local/bin/vault login -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem token=-
fi
\" > /root/cli-vault-auto-login.sh

    # make executable
    chmod +x /root/cli-vault-auto-login.sh

    echo \"Creating script to issue pki tokens\"
    # setup script to issue pki tokens
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
# redundant as also using in command line
export VAULT_CLIENT_CERT=/mnt/certs/cert.pem
export VAULT_CLIENT_KEY=/mnt/certs/key.pem
/usr/local/bin/vault token create -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem -policy=default -policy=pki -wrap-ttl=24h
\" > /root/issue-pki-token.sh

    # make executable
    chmod +x /root/issue-pki-token.sh

    echo \"Creating certificate rotation script\"
    # setup certificate rotation script
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
if [ -s /root/login.token ]; then
    LOGINTOKEN=\\\$(/bin/cat /root/login.token)
    HEADER=\\\$(echo \\\"X-Vault-Token: \\\"\\\$LOGINTOKEN)
    # we're using tls-client-validation so need cert, key, cacert, along with a login token, and payload.json file
    # we'll pass all this to the vault leader api and get back a json file with certificate data embedded
    # this payload.json was created in the setup of the server
    (umask 177; /usr/local/bin/curl --cacert /mnt/certs/ca.pem --cert /mnt/certs/cert.pem --key /mnt/certs/key.pem --header \\\"\\\$HEADER\\\" --request POST --data @/mnt/templates/payload.json https://\$IP:8200/v1/pki_int/issue/\$DATACENTER > /mnt/certs/vaultissue.json)
    # extract the required certificates to individual files
    /usr/local/bin/jq -r '.data.certificate' /mnt/certs/vaultissue.json > /mnt/certs/cert.pem
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json >> /mnt/certs/cert.pem
    (umask 137; /usr/local/bin/jq -r '.data.private_key' /mnt/certs/vaultissue.json > /mnt/certs/key.pem)
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json > /mnt/certs/ca.pem
    cd /mnt/certs
    # concat the root CA and intermediary CA into combined file
    cat CA_cert.pem ca.pem > combinedca.pem
    # steps here to hash ca files for ca-dir usage
    ln -s ca.pem hash/\\\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/ca.pem).0
    ln -s combinedca.pem hash/\\\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/combinedca.pem).0
    cd /root
    # set permissions on /mnt/certs for vault
    chown -R vault:certaccess /mnt/certs
    # restart services
    service vault reload
    service consul reload
    service consul status || service consul start
    service syslog-ng restart
else
    echo \\\"/root/login.token does not contain a token. Certificates cannot be renewed.\\\"
fi
\" > /root/rotate-certs.sh

    if [ -f /root/rotate-certs.sh ]; then
        # make executable
        chmod +x /root/rotate-certs.sh
        # add a crontab entry for every hour
        echo \"0 * * * * root /root/rotate-certs.sh >> /mnt/rotate-cert.log 2>&1\" >> /etc/crontab
    fi

    echo \"Adding vault-status.sh script\"
    # setup a quick way to check vault status
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
# redundant as also using in command line
export VAULT_CLIENT_CERT=/mnt/certs/cert.pem
export VAULT_CLIENT_KEY=/mnt/certs/key.pem
/usr/local/bin/vault status -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
\" > /root/vault-status.sh

    chmod +x /root/vault-status.sh

    echo \"Adding raft-status.sh script\"
    # setup a quick way to check raft status
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
# redundant as also using in command line
export VAULT_CLIENT_CERT=/mnt/certs/cert.pem
export VAULT_CLIENT_KEY=/mnt/certs/key.pem
/usr/local/bin/vault operator raft list-peers -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
\" > /root/raft-status.sh

    # make executable
    chmod +x /root/raft-status.sh

    # add script to regenerate 2h temp certs
    echo \"Adding gen-temp-certs.sh script to regenerate temporary certificates\"

    echo \"#!/bin/sh
MYNETWORK=\\\"\$SFTPNETWORK\\\"
COMMATONEWLINE=\\\$(echo \\\$MYNETWORK |sed 's/, /\n/g')
# diagnostic
echo \\\$COMMATONEWLINE > /tmpcerts/iplist.txt

# generate certificates per host
for sftphost in \\\$COMMATONEWLINE; do
    mkdir -p /tmpcerts/\\\$sftphost
    # use jo to generate payload.json file
    /usr/local/bin/jo -p common_name=\\\$sftphost ttl=2h ip_sans=\\\"\\\$sftphost,127.0.0.1\\\" format=pem > /tmpcerts/\\\$sftphost/payload.json
    if [ -s /root/login.token ]; then
        echo \\\"Generating 2 hour ttl client cert for ip \\\$sftphost in /tmpcerts/\\\$sftphost/...\\\"
        HEADER=\\\$(/bin/cat /root/login.token)
        for i in \\\$(jot 30); do
          echo \\\"issue round: \\\$i\\\"
          (umask 177; /usr/local/bin/curl -f --silent --cacert /mnt/certs/ca.pem --cert /mnt/certs/cert.pem --key /mnt/certs/key.pem --header \\\"X-Vault-Token: \\\$HEADER\\\" --request POST --data @/tmpcerts/\\\$sftphost/payload.json https://\$IP:8200/v1/pki_int/issue/\$DATACENTER > /tmpcerts/\\\$sftphost/vaultissue.json)
          if [ \\\$? -eq 0 ]; then
            break
          fi
          sleep 2
        done
        # extract the required certificates to individual files
        /usr/local/bin/jq -r '.data.certificate' /tmpcerts/\\\$sftphost/vaultissue.json > /tmpcerts/\\\$sftphost/cert.pem
        /usr/local/bin/jq -r '.data.issuing_ca' /tmpcerts/\\\$sftphost/vaultissue.json >> /tmpcerts/\\\$sftphost/cert.pem
        (umask 177; /usr/local/bin/jq -r '.data.private_key' /tmpcerts/\\\$sftphost/vaultissue.json > /tmpcerts/\\\$sftphost/key.pem)
        /usr/local/bin/jq -r '.data.issuing_ca' /tmpcerts/\\\$sftphost/vaultissue.json > /tmpcerts/\\\$sftphost/ca.pem
        # concat the root CA and intermediary CA into combined file
        cat /mnt/certs/CA_cert.pem /tmpcerts/\\\$sftphost/ca.pem > /tmpcerts/\\\$sftphost/combinedca.pem
        chown -R \\\$SFTPUSER:wheel /tmpcerts/\\\$sftphost/
        # validate the certificates
        echo \\\"Validating client certificate\\\"
        if [ -s /tmpcerts/\\\$sftphost/combinedca.pem ] && [ -s /tmpcerts/\\\$sftphost/cert.pem ]; then
            /usr/bin/openssl verify -CAfile /tmpcerts/\\\$sftphost/combinedca.pem /tmpcerts/\\\$sftphost/cert.pem
        fi
    fi
done
\" > /root/gen-temp-certs.sh

    # make executable
    chmod +x /root/gen-temp-certs.sh

    echo \"#!/bin/sh
if [ -z \\\$1 ]; then
    echo \\\"You need to pass in the IP address as first argument. This is the IP you want a certificate for.\\\"
    echo \\\"No IP validation is done so make sure you input a valid IP address.\\\"
    echo \\\"\\\"
    echo \\\"#  ./single-temp-cert.sh 10.0.0.2\\\"
    echo \\\"\\\"
    exit 1
fi
# read in arg1 as sftphost
sftphost=\\\$1
# diagnostic
echo \\\$sftphost >> /tmpcerts/singleiplist.txt
# generate certificates per host
mkdir -p /tmpcerts/\\\$sftphost
/usr/local/bin/jo -p common_name=\\\$sftphost ttl=2h ip_sans=\\\"\\\$sftphost,127.0.0.1\\\" format=pem > /tmpcerts/\\\$sftphost/payload.json
if [ -s /root/login.token ]; then
    echo \\\"Re-generating 2 hour ttl client cert for ip \\\$sftphost in /tmpcerts/\\\$sftphost/...\\\"
    HEADER=\\\$(/bin/cat /root/login.token)
    for i in \\\$(jot 30); do
      echo \\\"issue round: \\\$i\\\"
      (umask 177; /usr/local/bin/curl -f --silent --cacert /mnt/certs/ca.pem --cert /mnt/certs/cert.pem --key /mnt/certs/key.pem --header \\\"X-Vault-Token: \\\$HEADER\\\" --request POST --data @/tmpcerts/\\\$sftphost/payload.json https://\$IP:8200/v1/pki_int/issue/\$DATACENTER > /tmpcerts/\\\$sftphost/vaultissue.json)
      if [ \\\$? -eq 0 ]; then
        break
      fi
      sleep 2
    done
    # extract the required certificates to individual files
    /usr/local/bin/jq -r '.data.certificate' /tmpcerts/\\\$sftphost/vaultissue.json > /tmpcerts/\\\$sftphost/cert.pem
    /usr/local/bin/jq -r '.data.issuing_ca' /tmpcerts/\\\$sftphost/vaultissue.json >> /tmpcerts/\\\$sftphost/cert.pem
    (umask 177; /usr/local/bin/jq -r '.data.private_key' /tmpcerts/\\\$sftphost/vaultissue.json > /tmpcerts/\\\$sftphost/key.pem)
    /usr/local/bin/jq -r '.data.issuing_ca' /tmpcerts/\\\$sftphost/vaultissue.json > /tmpcerts/\\\$sftphost/ca.pem
    # concat the root CA and intermediary CA into combined file
    cat /mnt/certs/CA_cert.pem /tmpcerts/\\\$sftphost/ca.pem > /tmpcerts/\\\$sftphost/combinedca.pem
    chown -R \$SFTPUSER:wheel /tmpcerts/\\\$sftphost/
    # validate the certificates
    echo \\\"Validating client certificate\\\"
    if [ -s /tmpcerts/\\\$sftphost/combinedca.pem ] && [ -s /tmpcerts/\\\$sftphost/cert.pem ]; then
        /usr/bin/openssl verify -CAfile /tmpcerts/\\\$sftphost/combinedca.pem /tmpcerts/\\\$sftphost/cert.pem
    fi
fi
\" > /root/single-temp-cert.sh

    # make executable
    chmod +x /root/single-temp-cert.sh

###### not working
#    # setup token renewals
#    echo \"
#if [ -s /root/login.token ]; then
#    LOGINTOKEN=\\\$(/bin/cat /root/login.token)
#    echo \\\$LOGINTOKEN | /usr/local/bin/vault token renew -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem token=-
#else
#    echo "/root/login.token does not contain a token to be renewed."
#fi
#\" > /root/token-renew.sh
#
#    if [ -f /root/token-renew.sh ]; then
#        chmod +x /root/token-renew.sh
#    fi
########

    # end leader config
    ;;

    ### Vault type: RAFT cluster follower
    follower)

    # some basic ssh setup
    echo \"Initialising ssh settings\"
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    touch /root/.ssh/authorized_keys

    if [ -f /root/sshkey ] && [ ! -f /root/.ssh/id_rsa ]; then
        cp /root/sshkey /root/.ssh/id_rsa
        chmod 600 /root/.ssh/id_rsa
        ssh-keygen -f /root/.ssh/id_rsa -y > /root/.ssh/id_rsa.pub
    fi

    # setup temp directory for temp certs
    mkdir -p /tmp/tmpcerts

    # echo a message to user
    echo \"\"
    echo \"########################### IMPORTANT NOTICE ###########################\"
    echo \"\"
    echo \"Make sure to copy in id_rsa from vault leader certuser instance!\"
    echo \"\"
    echo \"########################################################################\"
    echo \"\"
    # end client

    # retrieve first round of certificates from vault leader via sftp
    echo \"Get first round of certificates from vault leader via sftp\"
    if [ -f /root/.ssh/id_rsa ]; then
        cd /tmp/tmpcerts
        # wildcard retrieval works manually but not in the script, so we specify each file to retrieve
        /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTLEADER:\$IP/cert.pem
        (umask 137; /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTLEADER:\$IP/key.pem)
        chgrp certaccess key.pem
        /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTLEADER:\$IP/ca.pem
        /usr/bin/sftp -P 8888 -o StrictHostKeyChecking=no -q \$SFTPUSER@\$VAULTLEADER:\$IP/combinedca.pem
    fi

    #set vault variables
    export VAULT_CLIENT_TIMEOUT=300s
    export VAULT_MAX_RETRIES=5

    #begin vault config
    echo \"disable_mlock = true
ui = true
# enable when vnet interface in use by pot
#listener \\\"tcp\\\" {
#  address = \\\"127.0.0.1:8200\\\"
#  tls_disable = 1
#}
listener \\\"tcp\\\" {
  address = \\\"\$IP:8200\\\"
  cluster_address = \\\"\$IP:8201\\\"
  telemetry {
    unauthenticated_metrics_access = true
  }
  # set to zero/false to enable TLS only
  tls_disable = false
  tls_require_and_verify_client_cert = true
  tls_skip_verify = false
  tls_client_ca_file = \\\"/mnt/certs/ca.pem\\\"
  tls_cert_file = \\\"/mnt/certs/cert.pem\\\"
  tls_key_file = \\\"/mnt/certs/key.pem\\\"
}
# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
# if using another directory update this path accordingly
storage \\\"raft\\\" {
  path    = \\\"/mnt/vault/\\\"
  node_id = \\\"\$NODENAME\\\"
  retry_join {
    leader_api_addr = \\\"https://\$VAULTLEADER:8200\\\"
    leader_ca_cert_file = \\\"/mnt/certs/ca.pem\\\"
    leader_client_cert_file = \\\"/mnt/certs/cert.pem\\\"
    leader_client_key_file = \\\"/mnt/certs/key.pem\\\"
  }
  autopilot_reconcile_interval = \\\"5s\\\"
}
seal \\\"transit\\\" {
  address = \\\"http://\$UNSEALIP:8200\\\"
  disable_renewal = \\\"false\\\"
  key_name = \\\"autounseal\\\"
  mount_path = \\\"transit/\\\"
  token = \\\"UNWRAPPEDTOKEN\\\"
}
telemetry {
  disable_hostname = true
  prometheus_retention_time = \\\"24h\\\"
}
#brb#service_registration \\\"consul\\\" {
#brb#  address = \\\"\$IP:8500\\\"
#brb#  scheme = \\\"http\\\"
#brb#  service = \\\"vault\\\"
#brb#  tls_ca_file = \\\"/mnt/certs/combinedca.pem\\\"
#brb#  tls_cert_file = \\\"/mnt/certs/cert.pem\\\"
#brb#  tls_key_file = \\\"/mnt/certs/key.pem\\\"
#brb#}
pid_file = \\\"/var/run/vault.pid\\\"
log_format = \\\"standard\\\"
log_level = \\\"Debug\\\"
api_addr = \\\"https://\$IP:8200\\\"
cluster_addr = \\\"https://\$IP:8201\\\"
#template {
#  source = \\\"/mnt/templates/cert.tpl\\\"
#  destination = \\\"/mnt/certs/cert.pem\\\"
#}
#template {
#  source = \\\"/mnt/templates/ca.tpl\\\"
#  destination = \\\"/mnt/certs/ca.pem\\\"
#}
#template {
#  source = \\\"/mnt/templates/key.tpl\\\"
#  destination = \\\"/mnt/certs/key.pem\\\"
#}
\" | (umask 177; cat > /usr/local/etc/vault.hcl)

    # Set permission for vault.hcl, so that vault can read it
    chown vault:wheel /usr/local/etc/vault.hcl

    # setup template files for certificates
    # not currently enabled via vault, using cron job to renew, combined, hashes combinedca.pem
    echo \"{{- /* /mnt/templates/cert.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$IP\\\" \\\"ttl=24h\\\" \\\"alt_names=\$NODENAME\\\" \\\"ip_sans=\$IP\\\" }}
{{ .Data.certificate }}{{ end }}
\" > /mnt/templates/cert.tpl

    echo \"{{- /* /mnt/templates/ca.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$IP\\\" }}
{{ .Data.issuing_ca }}{{ end }}
\" > /mnt/templates/ca.tpl

    echo \"{{- /* /mnt/templates/key.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$IP\\\" \\\"ttl=24h\\\" \\\"alt_names=\$NODENAME\\\" \\\"ip_sans=\$IP\\\" }}
{{ .Data.private_key }}{{ end }}
\" > /mnt/templates/key.tpl

    # set permissions on /mnt for vault data
    chown -R vault:wheel /mnt/vault

    # invite to certaccess group
    /usr/sbin/pw usermod vault -G certaccess

    # setup rc.conf entries
    # we do not set vault_user=vault because vault will not start
    service vault enable
    sysrc vault_login_class=root
    sysrc vault_syslog_output_enable=\"YES\"
    sysrc vault_syslog_output_priority=\"warn\"

    # if we need to autounseal with passed in unwrap token
    # vault unwrap [options] [TOKEN]
    (umask 177; /usr/local/bin/vault unwrap -address=http://\$UNSEALIP:8200 -format=json \$UNSEALTOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/unwrapped.token)
    if [ -s /root/unwrapped.token ]; then
        THIS_TOKEN=\$(/bin/cat /root/unwrapped.token)
        (umask 177; /usr/bin/sed -i .orig \"/UNWRAPPEDTOKEN/s/UNWRAPPEDTOKEN/\$THIS_TOKEN/g\" /usr/local/etc/vault.hcl)
    fi

    # new CA cert retrieval process with curl
    echo \"Retrieving CA certificates from Vault leader\"
    # get the root CA, we're not able to do any tls verification at this stage
    /usr/local/bin/curl --cacert /tmp/tmpcerts/ca.pem --cert /tmp/tmpcerts/cert.pem --key /tmp/tmpcerts/key.pem -o /mnt/certs/CA_cert.pem https://\$VAULTLEADER:8200/v1/pki/ca/pem
    # append a new line to the file, as will concat together later with another file
    if [ -s /mnt/certs/CA_cert.pem ]; then
        echo \"\" >> /mnt/certs/CA_cert.pem
    fi
    # get the intermediate CA, we're not able to do any tls verification at this stage
    /usr/local/bin/curl --cacert /tmp/tmpcerts/ca.pem --cert /tmp/tmpcerts/cert.pem --key /tmp/tmpcerts/key.pem -o /mnt/certs/intermediate.cert.pem https://\$VAULTLEADER:8200/v1/pki_int/ca/pem
    # append a new line to the file, as will concat together later with another file
    if [ -s /mnt/certs/intermediate.cert.pem ]; then
        echo \"\" >> /mnt/certs/intermediate.cert.pem
    fi
    # validate the certificates
    echo \"Validating CA certificates\"
    if [ -s /mnt/certs/CA_cert.pem ] && [ -s /mnt/certs/intermediate.cert.pem ]; then
        /usr/bin/openssl verify -CAfile /mnt/certs/CA_cert.pem /mnt/certs/intermediate.cert.pem
    fi

    # login to unseal vault to get a root token to login to the leader node
    echo \"Logging in to unseal vault to unseal\"
    (umask 177; /usr/local/bin/vault login -address=http://\$UNSEALIP:8200 -format=json \$THIS_TOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/this.token)
    echo \"Unseal login success. Please wait\"
    echo \"Please wait for cluster...\"
    for i in \$(jot 10); do
      echo \"round: \$i\"
      /usr/local/bin/vault status -address=http://\$UNSEALIP:8200
      if [ \$? -eq 0 ]; then
        break
      fi
      sleep 1
    done

    # login to the vault leader with full tls validation of client
    echo \"Logging in to vault leader instance to authenticate\"
    for i in \$(jot 30); do
      echo \"login round: \$i\"
      (umask 177; echo \"\$LEADERTOKEN\" | /usr/local/bin/vault login -address=https://\$VAULTLEADER:8200 -client-cert=/tmp/tmpcerts/cert.pem -client-key=/tmp/tmpcerts/key.pem -ca-cert=/mnt/certs/intermediate.cert.pem -method=token -field=token token=- > /root/login.token)
      if [ \$? -eq 0 ]; then
        break
      fi
      sleep 2
    done

    echo "Login success. Please wait"

    # get list of secrets engines (helps cluster to align)
    /usr/local/bin/vault secrets list -address=https://\$VAULTLEADER:8200 -client-cert=/tmp/tmpcerts/cert.pem -client-key=/tmp/tmpcerts/key.pem -ca-cert=/mnt/certs/intermediate.cert.pem

    # if a root login token exists with file size greater than zero, then setup a payload.json file for certificate request
    if [ -s /root/login.token ]; then
        # generate certificates to use
        # using this payload.json approach to avoid nested single and double quotes for expansion
        # new way of generating payload.json with jo
        /usr/local/bin/jo -p common_name=\$IP alt_names=\$NODENAME ttl=24h ip_sans=\"\$IP,127.0.0.1\" format=pem > /mnt/templates/payload.json

        # we use curl to get the certificates in json format from vault leader api, as vaults cli's issue command only has the formats: pem, pem_bundle, der
        # but no json format with everything in one file
        echo \"Generating certificates to use from Vault leader\"
        HEADER=\$(/bin/cat /root/login.token)
        (umask 177; /usr/local/bin/curl --cacert /tmp/tmpcerts/combinedca.pem --cert /tmp/tmpcerts/cert.pem --key /tmp/tmpcerts/key.pem --header \"X-Vault-Token: \$HEADER\" --request POST --data @/mnt/templates/payload.json https://\$VAULTLEADER:8200/v1/pki_int/issue/\$DATACENTER > /mnt/certs/vaultissue.json)
        # extract the required certificates to individual files
        /usr/local/bin/jq -r '.data.certificate' /mnt/certs/vaultissue.json > /mnt/certs/cert.pem
        # append the ca cert to the cert
        /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json >> /mnt/certs/cert.pem
        (umask 137; /usr/local/bin/jq -r '.data.private_key' /mnt/certs/vaultissue.json > /mnt/certs/key.pem)
        /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json > /mnt/certs/ca.pem
        cd /mnt/certs
        # concat the root CA and intermediary CA into combined file
        cat /mnt/certs/CA_cert.pem /mnt/certs/ca.pem > /mnt/certs/combinedca.pem
        # steps here to hash ca, required for syslog-ng
        ln -s ca.pem hash/\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/ca.pem).0
        ln -s combinedca.pem hash/\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/combinedca.pem).0
        cd /root
        # set permissions on /mnt/certs for vault
        chown -R vault:certaccess /mnt/certs

        # validate the certificates
        echo \"Validating client certificate\"
        if [ -s /mnt/certs/combinedca.pem ] && [ -s /mnt/certs/cert.pem ]; then
            /usr/bin/openssl verify -CAfile /mnt/certs/combinedca.pem /mnt/certs/cert.pem
        fi

        # enable consul components
        #rm# /usr/bin/sed -i .orig 's/#brb#//g' /usr/local/etc/vault.hcl
        (umask 177; /usr/bin/sed -i .orig 's/#brb#//g' /usr/local/etc/vault.hcl)

        # optional remote logging
        if [ ! -z \$REMOTELOG ] && [ \$REMOTELOG != \"null\" ]; then
            if [ -f /root/syslog-ng.conf ]; then
                /usr/bin/sed -i .orig \"s/REMOTELOGIP/\$REMOTELOG/g\" /root/syslog-ng.conf
                cp -f /root/syslog-ng.conf /usr/local/etc/syslog-ng.conf
                # stop syslogd
                service syslogd onestop || true
                # setup sysrc entries to start and set parameters to accept logs from remote subnet
                sysrc syslogd_enable=\"NO\"
                sysrc syslog_ng_enable=\"YES\"
                #sysrc syslog_ng_flags=\"-u daemon\"
                sysrc syslog_ng_flags=\"-R /tmp/syslog-ng.persist\"
                /usr/local/etc/rc.d/syslog-ng start
                echo \"syslog-ng setup complete\"
            else
                echo \"/root/syslog-ng.conf is missing?\"
            fi
        else
            echo \"REMOTELOG parameter is not set to an IP address. syslog-ng won't operate.\"
        fi

        ## start consul config
        # make consul configuration directory and set permissions
        mkdir -p /usr/local/etc/consul.d
        chown consul /usr/local/etc/consul.d
        chmod 750 /usr/local/etc/consul.d

        # Create the consul agent config file with imported variables
        echo \"{
\\\"advertise_addr\\\": \\\"\$IP\\\",
\\\"datacenter\\\": \\\"\$DATACENTER\\\",
\\\"node_name\\\": \\\"\$NODENAME\\\",
\\\"data_dir\\\":  \\\"/var/db/consul\\\",
\\\"dns_config\\\": {
 \\\"a_record_limit\\\": 3,
 \\\"enable_truncate\\\": true
},
\\\"verify_incoming\\\": true,
\\\"verify_outgoing\\\": true,
\\\"verify_server_hostname\\\": false,
\\\"verify_incoming_rpc\\\":true,
\\\"ca_file\\\": \\\"/mnt/certs/combinedca.pem\\\",
\\\"cert_file\\\": \\\"/mnt/certs/cert.pem\\\",
\\\"key_file\\\": \\\"/mnt/certs/key.pem\\\",
\\\"log_file\\\": \\\"/var/log/consul/\\\",
\\\"log_level\\\": \\\"WARN\\\",
\\\"encrypt\\\": \\\"\$GOSSIPKEY\\\",
\\\"start_join\\\": [ \$CONSULSERVERS ],
\\\"service\\\": {
 \\\"name\\\": \\\"node-exporter\\\",
 \\\"tags\\\": [\\\"_app=vault\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\"],
 \\\"port\\\": 9100
 }
}\" | (umask 177; cat > /usr/local/etc/consul.d/agent.json)

        # set owner and perms on agent.json
        chown consul:wheel /usr/local/etc/consul.d/agent.json

        # enable consul
        service consul enable

        # set load parameter for consul config
        sysrc consul_args=\"-config-file=/usr/local/etc/consul.d/agent.json\"
        #sysrc consul_datadir=\"/var/db/consul\"

        # setup consul logs, might be redundant if not specified in agent.json above
        mkdir -p /var/log/consul
        touch /var/log/consul/consul.log
        chown -R consul:wheel /var/log/consul

        # add the consul user to the certaccess group
        /usr/sbin/pw usermod consul -G certaccess

        ## end consul

        # node exporter needs tls setup
        echo \"tls_server_config:
  cert_file: /mnt/certs/cert.pem
  key_file: /mnt/certs/key.pem
\" > /usr/local/etc/node-exporter.yml

        # add node_exporter user
        /usr/sbin/pw useradd -n nodeexport -c 'nodeexporter user' \
         -m -s /usr/bin/nologin -h -

        # invite node_exporter to certaccess group
        /usr/sbin/pw usermod nodeexport -G certaccess

        # enable node_exporter service
        #rm# sysrc node_exporter_enable=\"YES\"
        service node_exporter enable
        sysrc node_exporter_args=\"--web.config=/usr/local/etc/node-exporter.yml\"
        sysrc node_exporter_user=nodeexport
        sysrc node_exporter_group=nodeexport

        # start consul agent
        service consul start

        # start node_exporter
        service node_exporter start

        # start vault
        echo \"Starting Vault Follower\"
        service vault start
        for i in \$(jot 10); do
          echo \"round: \$i\"
          /usr/local/bin/vault status -address=http://\$UNSEALIP:8200
          if [ \$? -eq 0 ]; then
            break
          fi
          sleep 1
        done

        # join the raft cluster
        echo \"Joining the raft cluster\"
        # we're using tls-client-validation so cert, key, cacert required
        /usr/local/bin/vault operator raft join -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
        # we need to wait a period for the cluster to initialise correctly and elect leader
        # cluster requires 10 seconds to bootstrap, even if single server, we can only login after 10 seconds
        # syslog-ng flow control adds a lot of overhead, so longer delay is required if enabled. 30s at least
        echo \"Please wait for raft cluster to contemplate self...\"

        # login to the local vault instance to initialise the follower node
        echo \"Logging in to local vault instance\"
        # we're using tls-client-validation so need cert, key, cacert and a login token
        for i in \$(jot 30); do
              echo \"login round: \$i\"
              (umask 177; echo \"\$LEADERTOKEN\" | /usr/local/bin/vault login -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem -method=token -field=token token=- > /root/login.token)
              if [ \$? -eq 0 ]; then
                break
              fi
              sleep 2
        done

        if [ -s /root/login.token ]; then
            TOKENOUT=\$(/bin/cat /root/login.token)
            echo \"Your token is \$TOKENOUT\"
            echo \"Also available in /root/login.token\"
        fi
    else
        echo \"ERROR: There was a problem logging into the vault leader and no certificates were retrieved. Vault not started.\"
    fi

    # setup auto-login script
    echo \"Setting up auto-login script\"
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
# redundant as also using in command line
export VAULT_CLIENT_CERT=/mnt/certs/cert.pem
export VAULT_CLIENT_KEY=/mnt/certs/key.pem
if [ -s /root/login.token ]; then
    /bin/cat /root/login.token | /usr/local/bin/vault login -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem token=-
fi\" > /root/cli-vault-auto-login.sh

    # set executable perms
    chmod +x /root/cli-vault-auto-login.sh

    # setup certificate rotation script
    echo \"Setting up certificate rotation script\"
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
if [ -s /root/login.token ]; then
    LOGINTOKEN=\\\$(/bin/cat /root/login.token)
    HEADER=\\\$(echo \\\"X-Vault-Token: \\\"\\\$LOGINTOKEN)
    (umask 177; /usr/local/bin/curl --cacert /mnt/certs/combinedca.pem --cert /mnt/certs/cert.pem --key /mnt/certs/key.pem --header \\\"\\\$HEADER\\\" --request POST --data @/mnt/templates/payload.json https://\$VAULTLEADER:8200/v1/pki_int/issue/\$DATACENTER > /mnt/certs/vaultissue.json)
    # extract the required certificates to individual files
    /usr/local/bin/jq -r '.data.certificate' /mnt/certs/vaultissue.json > /mnt/certs/cert.pem
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json >> /mnt/certs/cert.pem
    (umask 137; /usr/local/bin/jq -r '.data.private_key' /mnt/certs/vaultissue.json > /mnt/certs/key.pem)
    /usr/local/bin/jq -r '.data.issuing_ca' /mnt/certs/vaultissue.json > /mnt/certs/ca.pem
    cd /mnt/certs
    # concat the root CA and intermediary CA into combined file
    cat CA_cert.pem ca.pem > combinedca.pem
    # steps here to hash ca
    ln -s ca.pem hash\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/ca.pem).0
    ln -s combinedca.pem hash\$(/usr/bin/openssl x509 -subject_hash -noout -in /mnt/certs/combinedca.pem).0
    cd /root
    # set permissions on /mnt/certs for vault
    chown -R vault:certaccess /mnt/certs
    # restart services
    service vault reload
    service consul reload
    service consul status || service consul start
    service syslog-ng restart
else
    echo "/root/login.token does not contain a token. Certificates cannot be renewed."
fi
\" > /root/rotate-certs.sh

    if [ -f /root/rotate-certs.sh ]; then
        echo \"Adding cron job\"
        # make executable
        chmod +x /root/rotate-certs.sh
        # add a crontab entry for every hour
        echo \"0 * * * * root /root/rotate-certs.sh >> /mnt/rotate-cert.log 2>&1\" >> /etc/crontab
    fi

    echo \"Adding vault-status.sh script\"
    # setup a quick way to check vault status
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
# redundant as also using in command line
export VAULT_CLIENT_CERT=/mnt/certs/cert.pem
export VAULT_CLIENT_KEY=/mnt/certs/key.pem
/usr/local/bin/vault status -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
\" > /root/vault-status.sh

    # make executable
    chmod +x /root/vault-status.sh

    echo \"Adding raft-status.sh script\"
    # setup a quick way to check raft status
    echo \"#!/bin/sh
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
# redundant as also using in command line
export VAULT_CLIENT_CERT=/mnt/certs/cert.pem
export VAULT_CLIENT_KEY=/mnt/certs/key.pem
/usr/local/bin/vault operator raft list-peers -address=https://\$IP:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
\" > /root/raft-status.sh

    # make executable
    chmod +x /root/raft-status.sh

######## not working
#    # setup token renewals
#    echo \"
#if [ -s /root/login.token ]; then
#    LOGINTOKEN=\\\$(/bin/cat /root/login.token)
#    echo \\\$LOGINTOKEN | /usr/local/bin/vault token renew -address=https://\$VAULTLEADER:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem token=-
#else
#    echo "/root/login.token does not contain a token to be renewed."
#fi
#\" > /root/token-renew.sh
#
#    if [ -f /root/token-renew.sh ]; then
#        chmod +x /root/token-renew.sh
#    fi
#######

    # end follower config
    ;;

    # catch all, exit because bad VAULTTYPE
    *)
    echo \"there is a problem with the VAULTTYPE variable - set to unseal or leader or cluster\"
    exit 1
    # end catchall config
    ;;

esac

# end vault case statements #

# ADJUST THIS: START THE SERVICES AGAIN AFTER CONFIGURATION

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
