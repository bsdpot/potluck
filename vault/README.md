---
author: "Bretton Vine"
title: Vault 
summary: Vault is a tool for securely accessing secrets, such as API keys, passwords, or certificates.
tags: ["micro-services", "vault", "nomad", "secrets", "certificates"]
---

# Overview

This is a flavour containing the ```vault``` security storage platform.

You can e.g. store certificates, passwords etc to be used with the [nomad-server](https://potluck.honeyguide.net/blog/nomad-server/) ```pot``` flavour on this site.

The flavour expects a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. If no ```consul``` instance is available at first, make sure it's up within an hour and the certificate renewal process will restart ```consul```. You can also connect to this host and ```service consul restart``` manually.

## pro tip

Start ```vault``` cluster with the IP addresses of ```consul``` servers, which aren't live. Then start ```loki``` instance. Then start a ```consul``` cluster. Restart consul on ```vault``` and ```loki``` instances or wait for first certificate renewal after an hour.

# Installation

## Unseal node

* [unseal node] Create a ZFS data set on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/vaultunseal zroot/vaultunseal```
* Create your local jail from the image or the flavour files. 
* Mount in the ZFS data set you created:    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/vaultunseal```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8200:8200```   
* Adjust to your environment:    
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> -E IP=<IP address of this vault node> -E VAULTTYPE=unseal```    

## Vault leader

* [cluster node] Create a ZFS data set on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/vaultdata zroot/vaultdata```
* Create your local jail from the image or the flavour files. 
* Mount in the ZFS data set you created:    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/vaultdata```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8200:8200```   
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
  -E IP=<IP address of this vault node> -E VAULTTYPE=leader \
  -E UNSEALIP=<unseal vault IP> -E UNSEALTOKEN=<wrapped token generated on unseal node> \
  -E CONSULSERVERS=<correctly-quoted-array-consul-IPs> \
  -E SFTPUSER=<username> -E SFTPNETWORK="<list of comma-space separated IP addresses>" \
  -E GOSSIPKEY=<32 byte Base64 key from consul keygen> [-E REMOTELOG=<remote syslog IP>]
  ```    

The SFTPUSER parameter is used to create a user with SSH private keys, where you will need to export the private key to the host systems for follower nodes.

The SFTPNETWORK parameter is a list of IP addresses in comma_space format ( "10.0.0.1, 10.0.0.2, 10.0.0.3") to pre-generate 2h SSL certificates for, for initial vault logins by follower nodes and other images making use of vault.

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to, such as for the ```loki``` flavour on this site.

Important: the leader boot can take a while with certificate generation. Let it complete before adding followers. 

Once booted you will need to run ```./cli-vault-auto-login.sh``` for a login token to use on follower nodes, and export ```/home/certuser/.ssh/id_rsa``` to a file to import to follower nodes and other types of pot images.

To re-generate the temporary certificates for the array of initial IP addresses, run ```./gen-temp-certs.sh```.

To generate a single certificate for an IP address, run ```./single-temp-cert.sh <IP address>```, for example: ```./single-temp-cert.sh 10.0.0.1```.

You will need to generate new temporary certificates if two hours have passed since setting up the ```vault``` leader.

## Vault follower

* [cluster node] Create a ZFS data set on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/vaultdata zroot/vaultdata```
* Create your local jail from the image or the flavour files. 
* Mount in the ZFS data set you created:    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/vaultdata```
* Copy in the SSH private key for the user on the Vault leader:    
  ```pot copy-in -p <jailname> -s /root/sshkey -d /root/sshkey```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8200:8200```   
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
  -E IP=<IP address of this vault node> -E VAULTTYPE=follower \
  -E UNSEALIP=<unseal vault node> -E UNSEALTOKEN=<wrapped token generated on unseal node> -E VAULTLEADER=<IP> -E LEADERTOKEN=<token>
  -E CONSULSERVERS=<correctly-quoted-array-consul-IPs> \
  -E SFTPUSER=certuser -E GOSSIPKEY=<32 byte Base64 key from consul keygen> [-E REMOTELOG=<remote syslog IP>]
  ```

The SFTPUSER parameter is used on the follower node to login to the vault leader, to get temporary certificates for a further login.

The SFTPNETWORK parameter is only used by the Vault leader node.

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to, such as for the ```loki``` flavour on this site.

# Architecture
* vault-unseal: is initialized and unsealed. The root token creates a transit key that enables the other Vaults auto-unseal. This Vault server is not a part of the cluster.
* vault-clone-1: is initialized and unsealed automatically with the passed in wrapped unseal key. Joins raft cluster after unsealing, sets up PKI and generates a bunch of temporary certificates.
* vault-clone-2: is initialized and unsealed automatically with the passed in NEW wrapped unseal key. Joins raft cluster after unsealing, sets up PKI. Needs to have SSH key from vault leader.
* vault-clone-n+: is initialized and unsealed automatically with the passed in NEW wrapped unseal key. Joins raft cluster after unsealing, sets up PKI. Needs to have SSH key from vault leader.

# Usage

```vault``` is then running on port 8200 of your jail IP address.

## Unseal Node
(This stage of development of the pot image doesn't yet include HTTPS on the unseal node. Please include the parameter ```-address=http://<IP>:8200``` to any ```vault``` commands```)

This vault instance exists to generate unseal keys. It must first be initialised. Please save this information securely.

```
$ pot term vault-unseal
$ vault operator init -address=http://<IP>:8200

Unseal Key 1: key1
Unseal Key 2: key2
Unseal Key 3: key3
Unseal Key 4: key4
Unseal Key 5: key5

Initial Root Token: s.token

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 3 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.

$ vault operator unseal -address=http://<IP>:8200 "key1"
$ vault operator unseal -address=http://<IP>:8200 "key2"
$ vault operator unseal -address=http://<IP>:8200 "key3"

$ vault login -address=http://<IP>:8200

(using Initial Root Token)

$ ./setup-autounseal.sh
Success! Enabled the file audit device at: file/
Success! Enabled the transit secrets engine at: transit/
Success! Data written to: transit/keys/autounseal
Success! Uploaded policy: autounseal

$ ./issue-unseal.sh
Key                              Value
---                              -----
wrapping_token:                  s.newtoken
wrapping_accessor:               REDACTED
wrapping_token_ttl:              24h
wrapping_token_creation_time:    2021-05-29 13:52:13.743971005 +0000 UTC
wrapping_token_creation_path:    auth/token/create
wrapped_accessor:                REDACTED
```

This new token ```s.newtoken``` can be used to unseal the cluster nodes. A new token must be generated for each node in the vault cluster.

### Important note
If the unseal node is restarted you will need to unseal and login again. Shut down your ```vault``` cluster first, starting with followers, then leader. Start unseal node, unseal and login, then start leader and followers.

You did save the keys and login token right?

## Cluster leader node using raft storage
To unseal a cluster leader, make use of a wrapped key generated on the unseal node. Pass it in with ```-E UNSEALTOKEN=<wrapped token>```

Once running, you can login and run the script ```/root/cli-vault-auto-login.sh``` to automatically login to vault in the CLI and return a token for use in additional vault instances, in addition to an unseal token.

To generate a token for PKI, run ```pot term vault-clone``` and then ```/root/issue-pki-token.sh```.

To run other ```vault``` commands pass in the extra parameters ```-address=https://<IP-being-queried>:8200``` and one of:
* ```-tls-skip-verify``` to skip verifying the certificate; or
* ```-ca-cert=/mnt/certs/combinedca.pem``` to verify with the CA certificate obtained (if everything working)

### Example vault command with parameters
```
vault status -address=https://10.0.0.3:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
vault operator raft list-peers -address=https://10.0.0.3:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
vault operator raft autopilot state -address=https://10.0.0.3:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
```

## Cluster follower follower using raft storage
To unseal a cluster follower, make use of a wrapped key generated on the unseal node. Pass it in with ```-E UNSEALTOKEN=<wrapped token>```

A leader node should already exist, and must be passed in with the parameter ```-E VAULTLEADER=<IP>```.

A leader token is also required and must be passed in with the parameter ```-E LEADERTOKEN=<login token from unsealed leader>```. You can get this token from ```/root/cli-vault-auto-login.sh``` on the leader.

The SSH key created for the SFTPUSER on the Vault leader needs to be made available during pot setup of the follower node.

The cluster node will be automatically unsealed and join the cluster. It will automatically retrieve a temporary certificate with 2h TTL from the Vault leader via SFTP, and use this to perform a client-tls-validated login to vault, to retrieve proper certificates with a longer TTL of 24h.

Repeat for all additional nodes in the vault cluster.

To run other ```vault``` commands pass in the extra parameters ```-address=https://<IP-being-queried>:8200``` and ```-client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem``` to verify with the CA certificate obtained (if everything working)

### Example vault command with parameters
```
vault status -address=https://10.0.0.3:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
vault operator raft list-peers -address=https://10.0.0.3:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
vault operator raft autopilot state -address=https://10.0.0.3:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem
```

## Default cluster usage
This cluster will generate, issue, renew certificates. 

## Other example cluster usage
This cluster can be used as a kv store.

```
vault secrets enable -address=https://<IP>:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem -path=kv kv-v2
vault kv -address=https://<IP>:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem put kv/testkey webapp=TESTKEY
vault kv -address=https://<IP>:8200 -client-cert=/mnt/certs/cert.pem -client-key=/mnt/certs/key.pem -ca-cert=/mnt/certs/combinedca.pem get kv/testkey
```
