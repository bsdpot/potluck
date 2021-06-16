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

# we need consul for consul agent
step "Install package consul"
pkg install -y consul

# vault can handle templating now but may still be required
step "Install package consul-template"
pkg install -y consul-template

step "Install package vault"
pkg install -y vault

step "Add vault user to daemon class"
pw usermod vault -G daemon

step "Install package sudo"
pkg install -y sudo

step "Install package node_exporter"
pkg install -y node_exporter

step "Install package jq"
pkg install -y jq

step "Install package curl"
pkg install -y curl

step "Clean package installation"
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
/usr/local/etc/rc.d/consul onestop || true
/usr/local/etc/rc.d/vault onestop  || true

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
if [ -z \${DATACENTER+x} ]; then
    echo 'DATACENTER is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${NODENAME+x} ];
then
    echo 'NODENAME is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${CONSULSERVERS+x} ]; then
    echo 'CONSULSERVERS is unset - see documentation how to configure this flavour'
    exit 1
fi
if [ -z \${IP+x} ]; then
    echo 'IP is unset - see documentation how to configure this flavour'
    exit 1
fi
# GOSSIPKEY is a 32 byte, Base64 encoded key generated with consul keygen for the consul flavour.
# Re-used for nomad, which is usually 16 byte key but supports 32 byte, Base64 encoded keys
# We'll re-use the one from the consul flavour
if [ -z \${GOSSIPKEY+x} ];
then
    echo 'GOSSIPKEY is unset - see documentation how to configure this flavour, defaulting to preset encrypt key. Do not use this in production!'
    GOSSIPKEY='\"BY+vavBUSEmNzmxxS3k3bmVFn1giS4uEudc774nBhIw=\"'
fi
# this defaults to unseal. Other options are leader for a raft cluster leader, and cluster, for a raft cluster peer.
if [ -z \${VAULTTYPE+x} ];
then
    echo 'VAULTTYPE is unset - see documentation how to configure this flavour, defaulting to unseal instead of leader or follower.'
    VAULTTYPE=\"unseal\"
fi
# IP address of the unseal server
if [ -z \${UNSEALIP+x} ];
then
    echo 'UNSEALIP is unset - see documentation how to configure this flavour, defaulting to preset value. Do not use this in production!'
    UNSEALIP=\"127.0.0.1\"
fi
# Unwrap token to pass into cluster
if [ -z \${UNSEALTOKEN+x} ];
then
    echo 'UNSEALTOKEN is unset - see documentation how to configure this flavour, defaulting to unset value. Do not use this in production!'
    UNSEALTOKEN=\"unset\"
fi
# Vault leader IP
if [ -z \${VAULTLEADER+x} ];
then
    echo 'VAULTLEADER is unset - see documentation how to configure this flavour, defaulting to own IP.'
    VAULTLEADER=\"\$IP\"
fi
# Vault leader token
if [ -z \${LEADERTOKEN+x} ];
then
    echo 'LEADERTOKEN is unset - see documentation how to configure this flavour, defaulting to unset.'
    VAULTLEADER=\"unset\"
fi


# ADJUST THIS BELOW: NOW ALL THE CONFIGURATION FILES NEED TO BE CREATED:
# Don't forget to double(!)-escape quotes and dollar signs in the config files

# setup /tmp/templates and /tmp/certs for vault usage
mkdir -p /tmp/templates
mkdir -p /tmp/certs

## start consul

# make consul configuration directory and set permissions
mkdir -p /usr/local/etc/consul.d
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
 \\\"log_file\\\": \\\"/var/log/consul/\\\",
 \\\"log_level\\\": \\\"WARN\\\",
 \\\"encrypt\\\": \$GOSSIPKEY,
 \\\"start_join\\\": [ \$CONSULSERVERS ],
 \\\"service\\\": {
  \\\"name\\\": \\\"node-exporter\\\",
  \\\"tags\\\": [\\\"_app=vault\\\", \\\"_service=node-exporter\\\", \\\"_hostname=\$NODENAME\\\"],
  \\\"port\\\": 9100
 }
}\" > /usr/local/etc/consul.d/agent.json

# set owner and perms on agent.json
chown consul:wheel /usr/local/etc/consul.d/agent.json
chmod 640 /usr/local/etc/consul.d/agent.json

# enable consul
sysrc consul_enable=\"YES\"

# set load parameter for consul config
sysrc consul_args=\"-config-file=/usr/local/etc/consul.d/agent.json\"
#sysrc consul_datadir=\"/var/db/consul\"

# Workaround for bug in rc.d/consul script:
sysrc consul_group=\"wheel\"

# setup consul logs, might be redundant if not specified in agent.json above
mkdir -p /var/log/consul
touch /var/log/consul/consul.log
chown -R consul:wheel /var/log/consul

# add the consul user to the wheel group, this seems to be required for
# consul to start on this instance. May need to figure out why.
# I'm not entirely sure this is the correct way to do it
/usr/sbin/pw usermod consul -G wheel

## end consul

# enable node_exporter service
sysrc node_exporter_enable=\"YES\"

## start Vault

if [ -f /usr/local/etc/vault/vault-server.hcl ]; then
    rm /usr/local/etc/vault/vault-server.hcl
fi

# default freebsd vault.hcl is /usr/local/etc/vault.hcl and
# the init script /usr/local/etc/rc.d/vault refers to this
# but many vault docs refer to /usr/local/etc/vault/vault-server.hcl
# or similar

# Create vault configuration file
# Three types of vault servers
# - unseal (unseal node)
# - leader (raft cluster leader)
# - cluster (raft cluster member)

case \$VAULTTYPE in

  ### Vault type: Gapped Unseal Node
  unseal)
    echo \"disable_mlock = true
ui = true
listener \\\"tcp\\\" {
  address = \\\"\$IP:8200\\\"
  tls_disable = 1
}
# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
storage \\\"file\\\" {
  path    = \\\"/mnt/\\\"
}
api_addr = \\\"http://\$IP:8200\\\"
log_level = \\\"Warn\\\"
\" > /usr/local/etc/vault.hcl

    # setup autounseal config
    echo \"path \\\"transit/encrypt/autounseal\\\" {
  capabilities = [ \\\"update\\\" ]
}
path \\\"transit/decrypt/autounseal\\\" {
  capabilities = [ \\\"update\\\" ]
}
\" > /root/autounseal.hcl

    # set variables, but don't all seem to be honoured
    VAULT_ADDR=\\\"http://\$IP:8200\\\"
    VAULT_API_ADDR=\\\"http://\$IP:8200\\\"
    VAULT_CLIENT_TIMEOUT=90s
    VAULT_MAX_RETRIES=5

    # set permissions on /mnt for vault data
    chown -R vault:wheel /mnt
    # setup rc.conf entries
    # we do not set vault_user=vault because vault will not start
    sysrc vault_enable=yes
    sysrc vault_login_class=root
    sysrc vault_syslog_output_enable=\"YES\"
    sysrc vault_syslog_output_priority=\"warn\"

    # start vault
    echo \"Starting Vault Unseal Node\"
    /usr/local/etc/rc.d/vault start

    # start consul agent
    /usr/local/etc/rc.d/consul start

    # start node_exporter
    /usr/local/etc/rc.d/node_exporter start
    ;;

    ### Vault type: RAFT Leader
    leader)
    echo \"disable_mlock = true
ui = true
listener \\\"tcp\\\" {
  address = \\\"\$IP:8200\\\"
  cluster_address = \\\"\$IP:8201\\\"
  # set to zero to enable TLS only
  tls_disable = 1
  # To configure the listener to use a CA certificate, concatenate the primary certificate and the CA certificate together
  # The primary certificate should appear first in the combined file.
  #xyz#tls_ca_file = /tmp/certs/vaultca.pem
  #xyz#tls_cert_file = /tmp/certs/vaultcert.pem
  #xyz#tls_key_file = /tmp/certs/vaultkey.pem
}
# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
storage \\\"raft\\\" {
  path    = \\\"/mnt/\\\"
  node_id = \\\"\$NODENAME\\\"
}
# we are a secondary server joining a cluster
seal \\\"transit\\\" {
  address = \\\"http://\$UNSEALIP:8200\\\"
  disable_renewal = \\\"false\\\"
  key_name = \\\"autounseal\\\"
  mount_path = \\\"transit/\\\"
  token = \\\"UNWRAPPEDTOKEN\\\"
}
service_registration \\\"consul\\\" {
  address = \\\"\$IP:8500\\\"
  scheme = \\\"http\\\"
  service = \\\"vault\\\"
  #tls_ca_file = \\\"/tmp/certs/consulca.pem\\\"
  #tls_cert_file = \\\"/tmp/certs/consulcert.pem\\\"
  #tls_key_file = \\\"/tmp/certs/consulkey.pem\\\"
}
api_addr = \\\"http://\$IP:8200\\\"
cluster_addr = \\\"http://\$IP:8201\\\"
\" > /usr/local/etc/vault.hcl

    # set variables, but don't all seem to be honoured
    VAULT_ADDR=\\\"http://\$IP:8200\\\"
    VAULT_CLUSTER_ADDR=\\\"http://\$IP:8201\\\"
    VAULT_API_ADDR=\\\"http://\$IP:8200\\\"
    VAULT_CLIENT_TIMEOUT=90s
    VAULT_MAX_RETRIES=5
    # set permissions on /mnt for vault data
    chown -R vault:wheel /mnt
    # setup rc.conf entries
    # we do not set vault_user=vault because vault will not start
    sysrc vault_enable=yes
    sysrc vault_login_class=root
    sysrc vault_syslog_output_enable=\"YES\"
    sysrc vault_syslog_output_priority=\"warn\"
    # if we need to autounseal with passed in unwrap token
    # vault unwrap [options] [TOKEN]
    /usr/local/bin/vault unwrap -address=http://\$UNSEALIP:8200 -format=json \$UNSEALTOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/unwrapped.token
    if [ -s /root/unwrapped.token ]; then
        THIS_TOKEN=\$(/bin/cat /root/unwrapped.token)
        /usr/bin/sed -i .orig \"/UNWRAPPEDTOKEN/s/UNWRAPPEDTOKEN/\$THIS_TOKEN/g\" /usr/local/etc/vault.hcl
    fi
    # start vault
    echo \"Starting Vault Leader\"
    /usr/local/etc/rc.d/vault start
    # login
    echo \"Logging in to unseal vault\"
    /usr/local/bin/vault login -address=http://\$UNSEALIP:8200 -format=json \$THIS_TOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/this.token
    sleep 5
    echo \"initiating raft cluster with operator init\"
    # perform operator init on unsealed node and get recovery keys instead of unseal keys, save to file
    /usr/local/bin/vault operator init -address=http://\$IP:8200 -format=json > /root/recovery.keys

    # set some variables from the saved file
    # this saved file may be a security risk?
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

    echo \"Please wait for cluster...\"
    sleep 2

    echo \"Joining the raft cluster\"
    /usr/local/bin/vault operator raft join -address=http://\$IP:8200

    # we need to wait a period for the cluster to initialise correctly and elect leader
    # cluster requires 10 seconds to bootstrap, even if single server, we can only login after
    echo \"Please wait for raft cluster to contemplate self...\"
    sleep 11

    echo \"Logging in to local raft instance\"
    echo \"\$ROOTKEY\" | /usr/local/bin/vault login -address=http://\$IP:8200 -method=token -field=token token=- > /root/login.token

    if [ -s /root/login.token ]; then
        TOKENOUT=\$(/bin/cat /root/login.token)
        echo \"Your token is \$TOKENOUT\"
        echo \"Also available in /root/login.token\"

        # setup logging
        echo \"enabling /mnt/audit.log\"
        /usr/local/bin/vault audit enable -address=http://\$IP:8200 file file_path=/mnt/audit.log

        # enable pki and become a CA
        echo \"Setting up raft cluster CA\"
        echo \"\"
        # vault secrets enable [options] TYPE
        echo \"Enabling PKI\"
        /usr/local/bin/vault secrets enable -address=http://\$IP:8200 pki
        # vault secrets tune [options] PATH
        echo \"Tuning PKI\"
        /usr/local/bin/vault secrets tune -max-lease-ttl=87600h -address=http://\$IP:8200 pki/
        # vault write [options] PATH [DATA K=V...]
        echo \"Generating internal certificate\"
        /usr/local/bin/vault write -address=http://\$IP:8200 -field=certificate pki/root/generate/internal common_name=\"\$DATACENTER\" ttl=87600h > /tmp/certs/CA_cert.crt
        echo \"Writing certificate URLs\"
        /usr/local/bin/vault write -address=http://\$IP:8200 pki/config/urls issuing_certificates=\"http://\$IP:8200/v1/pki/ca\" crl_distribution_points=\"http://\$IP:8200/v1/pki/crl\"

        # setup intermediate CA
        echo \"Setting up raft cluster intermediate CA\"

        # vault secrets enable [options] TYPE
        echo \"Enabling PKI Intermediate\"
        /usr/local/bin/vault secrets enable -address=http://\$IP:8200 -path=pki_int pki

        # vault secrets tune [options] PATH
        echo \"Tuning PKI Intermediate\"
        /usr/local/bin/vault secrets tune -max-lease-ttl=43800h -address=http://\$IP:8200 pki_int/

        # vault write [options] PATH [DATA K=V...]
        echo \"Writing intermediate certificate to file\"
        /usr/local/bin/vault write -address=http://\$IP:8200 -format=json pki_int/intermediate/generate/internal common_name=\"\$DATACENTER Intermediate Authority\" | /usr/local/bin/jq -r '.data.csr' > /tmp/certs/pki_intermediate.csr
        echo \"Signing intermediate certificate\"
        /usr/local/bin/vault write -address=http://\$IP:8200 -format=json pki/root/sign-intermediate csr=@/tmp/certs/pki_intermediate.csr format=pem_bundle ttl=\"43800h\" | /usr/local/bin/jq -r '.data.certificate' > /tmp/certs/intermediate.cert.pem
        echo \"Storing intermediate certificate\"
        /usr/local/bin/vault write -address=http://\$IP:8200 pki_int/intermediate/set-signed certificate=@/tmp/certs/intermediate.cert.pem

        # setup roles
        echo \"Setting up roles\"
        # vault write [options] PATH [DATA K=V...]
        /usr/local/bin/vault write -address=http://\$IP:8200 pki_int/roles/\$DATACENTER allow_any_name=true allow_bare_domains=true allow_subdomains=true max_ttl=\"720h\" require_cn=false generate_lease=true
        /usr/local/bin/vault write -address=http://\$IP:8200 pki_int/issue/\$DATACENTER common_name=\"\$DATACENTER\" ttl=\"24h\"
        /usr/local/bin/vault write -address=http://\$IP:8200 pki/roles/\$DATACENTER allow_any_name=true allow_bare_domains=true allow_subdomains=true max_ttl=\"72h\" require_cn=false

        # set policy in a file, will import next
        # this needs a review, combined from multiple sources
        echo \"Writing detailed vault policy to file /root/policy\"
        echo \"path \\\"pki*\\\" { capabilities = [\\\"read\\\", \\\"list\\\"] }
path \\\"pki/roles/\$DATACENTER\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki/sign/\$DATACENTER\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki/issue/\$DATACENTER\\\" { capabilities = [\\\"create\\\"] }
path \\\"pki_int/issue/*\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki_int/certs\\\" { capabilities = [\\\"list\\\"] }
path \\\"pki_int/revoke\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki_int/tidy\\\" { capabilities = [\\\"create\\\", \\\"update\\\"] }
path \\\"pki/cert/ca\\\" { capabilities = [\\\"read\\\"] }
path \\\"auth/token/renew\\\" { capabilities = [\\\"update\\\"] }
path \\\"auth/token/renew-self\\\" { capabilities = [\\\"update\\\"] }
\" > /root/vault.policy

        echo \"Writing vault policy to Vault\"
        # vault policy write [options] NAME PATH
        /usr/local/bin/vault policy write -address=http://\$IP:8200 pki /root/vault.policy
    fi

    # setup template files for certificates
    echo \"{{- /* /tmp/templates/cert.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$NODENAME\\\" }}
{{ .Data.certificate }}{{ end }}
\" > /tmp/templates/cert.tpl

    echo \"{{- /* /tmp/templates/ca.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$NODENAME\\\" }}
{{ .Data.issuing_ca }}{{ end }}
\" > /tmp/templates/ca.tpl

    echo \"{{- /* /tmp/templates/key.tpl */ -}}
{{ with secret \\\"pki_int/issue/\$DATACENTER\\\" \\\"common_name=\$NODENAME\\\" }}
{{ .Data.private_key }}{{ end }}
\" > /tmp/templates/key.tpl

    # update vault.hcl
    echo \"
template {
  source = \\\"/tmp/templates/cert.tpl\\\"
  destination = \\\"/tmp/certs/vaultcert.pem\\\"
}
template {
  source = \\\"/tmp/templates/ca.tpl\\\"
  destination = \\\"/tmp/certs/vaultca.pem\\\"
}
template {
  source = \\\"/tmp/templates/key.tpl\\\"
  destination = \\\"/tmp/certs/vaultkey.pem\\\"
}
\" >> /usr/local/etc/vault.hcl

    # generate certificates to use
    # were using curl to get the certificates in json format as regular issue only has format pem, pem_bundle and der
    if [ -s /root/login.token ]; then
        HEADER=\$(/bin/cat /root/login.token)
        /usr/local/bin/curl --header \"X-Vault-Token: \$HEADER\" --request POST --data '{\"common_name\": \"'\"\$NODENAME\"'\", \"ttl\": \"24h\"}' http://\$IP:8200/v1/pki_int/issue/\$DATACENTER > /tmp/certs/vaultissue.json
        # cli requires [], but web api does not
        #/usr/local/bin/jq -r '.data.issuing_ca[]' /tmp/certs/vaultissue.json > /tmp/certs/vaultca.pem
        # if left in for this script, you will get error 'Cannot iterate over string'
        /usr/local/bin/jq -r '.data.issuing_ca' /tmp/certs/vaultissue.json > /tmp/certs/vaultca.pem
        /usr/local/bin/jq -r '.data.certificate' /tmp/certs/vaultissue.json > /tmp/certs/vaultcert.pem
        /usr/local/bin/jq -r '.data.private_key' /tmp/certs/vaultissue.json > /tmp/certs/vaultkey.pem
    fi

    # if we get a successful private key, update vault.hcl and reload
    if [ -s /tmp/certs/vaultkey.pem ]; then
        # enable TLS by removing the config line disabling it
        /usr/bin/sed -i .orig 's/tls_disable/#tls_disable/g' /usr/local/etc/vault.hcl

        # remove the comment #xyz# to enable certificates
        /usr/bin/sed -i .orig 's/#xyz#tls/tls/g' /usr/local/etc/vault.hcl

        # reload vault
        /usr/local/etc/rc.d/vault reload
    fi

    # setup auto-login script
    echo \"#!/bin/sh
if [ -s /root/login.token ]; then
    /bin/cat /root/login.token | /usr/local/bin/vault login -address=http://\$IP:8200 token=-
fi\" > /root/cli-vault-auto-login.sh

    # make executable
    chmod +x /root/cli-vault-auto-login.sh

    # setup script to issue pki tokens
    echo \"#!/bin/sh
/usr/local/bin/vault token create -address=http://\$IP:8200 -policy=\\\"default\\\" -policy=\\\"pki\\\" -wrap-ttl=24h
\" > /root/issue-pki-token.sh

    # make executable
    chmod +x /root/issue-pki-token.sh

    # start consul agent
    /usr/local/etc/rc.d/consul start

    # start node_exporter
    /usr/local/etc/rc.d/node_exporter start

    ;;

    ### Vault type: RAFT cluster follower
    follower)

    echo \"disable_mlock = true
ui = true
listener \\\"tcp\\\" {
  address = \\\"\$IP:8200\\\"
  cluster_address = \\\"\$IP:8201\\\"
  # set to zero to enable TLS only
  tls_disable = 1
}
# make sure you create a zfs partition and mount it into /mnt
# if you want persistent vault data
storage \\\"raft\\\" {
  path    = \\\"/mnt/\\\"
  node_id = \\\"\$NODENAME\\\"
  retry_join {
    leader_api_addr = \\\"http://\$VAULTLEADER:8200\\\"
    #leader_ca_cert_file = \\\"/tmp/certs/ca\\\"
    #leader_client_cert_file = \\\"/tmp/certs/cert.pem\\\"
    #leader_client_key_file = \\\"/tmp/certs/cert.key\\\"
  }
}
# we are a secondary server joining a cluster
seal \\\"transit\\\" {
  address = \\\"http://\$UNSEALIP:8200\\\"
  disable_renewal = \\\"false\\\"
  key_name = \\\"autounseal\\\"
  mount_path = \\\"transit/\\\"
  token = \\\"UNWRAPPEDTOKEN\\\"
}
service_registration \\\"consul\\\" {
  address = \\\"\$IP:8500\\\"
  scheme = \\\"http\\\"
  service = \\\"vault\\\"
  #tls_ca_file = \\\"/tmp/certs/ca\\\"
  #tls_cert_file = \\\"/tmp/certs/cert.pem\\\"
  #tls_key_file = \\\"/tmp/certs/vert.key\\\"
}
api_addr = \\\"http://\$IP:8200\\\"
cluster_addr = \\\"http://\$IP:8201\\\"
\" > /usr/local/etc/vault.hcl

    # set variables, but don't all seem to be honoured
    VAULT_ADDR=\\\"http://\$IP:8200\\\"
    VAULT_CLUSTER_ADDR=\\\"http://\$IP:8201\\\"
    VAULT_API_ADDR=\\\"http://\$IP:8200\\\"
    VAULT_CLIENT_TIMEOUT=90s
    VAULT_MAX_RETRIES=5

    # set permissions on /mnt for vault data
    chown -R vault:wheel /mnt
    # setup rc.conf entries
    # we do not set vault_user=vault because vault will not start
    sysrc vault_enable=yes
    sysrc vault_login_class=root
    sysrc vault_syslog_output_enable=\"YES\"
    sysrc vault_syslog_output_priority=\"warn\"

    # if we need to autounseal with passed in unwrap token
    # vault unwrap [options] [TOKEN]
    /usr/local/bin/vault unwrap -address=http://\$UNSEALIP:8200 -format=json \$UNSEALTOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/unwrapped.token
    if [ -s /root/unwrapped.token ]; then
        THIS_TOKEN=\$(/bin/cat /root/unwrapped.token)
        /usr/bin/sed -i .orig \"/UNWRAPPEDTOKEN/s/UNWRAPPEDTOKEN/\$THIS_TOKEN/g\" /usr/local/etc/vault.hcl
    fi
    # start vault
    echo \"Starting Vault Leader\"
    /usr/local/etc/rc.d/vault start
    # login
    echo \"Logging in to unseal vault\"
    /usr/local/bin/vault login -address=http://\$UNSEALIP:8200 -format=json \$THIS_TOKEN | /usr/local/bin/jq -r '.auth.client_token' > /root/this.token
    sleep 5

    echo \"Joining the raft cluster\"
    /usr/local/bin/vault operator raft join -address=http://\$VAULTLEADER:8200

    # we need to wait a period for the cluster to initialise correctly and elect leader
    # cluster requires 10 seconds to bootstrap, even if single server, we can only login after
    echo \"Please wait for raft cluster to contemplate self...\"
    sleep 11

    echo \"Logging in to local raft instance\"
    echo \"\$LEADERTOKEN\" | /usr/local/bin/vault login -address=http://\$IP:8200 -method=token -field=token token=- > /root/login.token

    if [ -s /root/login.token ]; then
        TOKENOUT=\$(/bin/cat /root/login.token)
        echo \"Your token is \$TOKENOUT\"
        echo \"Also available in /root/login.token\"
    fi

    # setup auto-login script
    echo \"#!/bin/sh
if [ -s /root/login.token ]; then
    /bin/cat /root/login.token | /usr/local/bin/vault login -address=http://\$IP:8200 token=-
fi\" > /root/cli-vault-auto-login.sh
    chmod +x /root/cli-vault-auto-login.sh

    # start consul agent
    /usr/local/etc/rc.d/consul start

    # start node_exporter
    /usr/local/etc/rc.d/node_exporter start
    ;;

    *)
    echo \"there is a problem with the VAULTTYPE variable - set to unseal or leader or cluster\"
    exit 1
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
