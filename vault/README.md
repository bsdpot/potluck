---
author: "Bretton Vine"
title: Vault 
summary: Vault is a tool for securely accessing secrets, such as API keys, passwords, or certificates.
tags: ["micro-services", "vault", "nomad", "secrets", "certificates"]
---

# Overview

This is a flavour containing the ```vault``` security storage platform.

You can e.g. store certificates, passwords etc to be used with the [nomad-server](https://potluck.honeyguide.net/blog/nomad-server/) ```pot``` flavour on this site.

The flavour expects a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Disclaimer
This image uses the ports tree from github to obtain the latest version of ```vault```. Expect 25-30min build times if building this image from scratch.

As this results in a large potluck image, it will be a temporary solution, until ```pkg``` has it.

# Installation

* [unseal node] Create a ZFS dataset on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/vaultunseal zroot/vaultunseal```
* [cluster node] Create a ZFS dataset on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/vaultdata zroot/vaultdata```
* Create your local jail from the image or the flavour files. 
* Mount in the ZFS dataset you created:    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/vault[unseal|data]```
* Export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8200:8200```   
* Adjust to your environment:    
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> -E CONSULSERVERS=<correctly-quoted-array-consul-IPs> -E IP=<IP address of this vault node> -E VAULTTYPE=<unseal|leader|follower> [-E GOSSIPKEY=<32 byte Base64 key from consul keygen> -E UNSEALIP=<unseal vault node> -E UNSEALTOKEN=<wrapped token generated on unseal node> -E VAULTLEADER=<IP> -E LEADERTOKEN=<token> ]```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

# Architecture
* vault-unseal: is initialized and unsealed. The root token creates a transit key that enables the other Vaults auto-unseal. This Vault server is not a part of the cluster.
* vault-clone-1: is initialized and unsealed automatically with the passed in wrapped unseal key. Joins raft cluster after unsealing, sets up PKI.
* vault-clone-2: is initialized and unsealed automatically with the passed in NEW wrapped unseal key. Joins raft cluster after unsealing, sets up PKI.
* vault-clone-n+: is initialized and unsealed automatically with the passed in NEW wrapped unseal key. Joins raft cluster after unsealing, sets up PKI.

# Usage

```vault``` is then running on port 8200 of your jail IP address.

## Unseal Node
(This stage of development of the pot image doesn't yet include HTTPS. Please include the parameter ```-address=http://<IP>:8200``` to any ```vault``` commands```)

This vault instance exists to generate unseal keys. It must first be initialised.

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

$ vault audit enable -address=http://<IP>:8200 file file_path=/mnt/audit.log 
Success! Enabled the file audit device at: file/

$ vault secrets enable -address=http://<IP>:8200 transit 
Success! Enabled the transit secrets engine at: transit/

$ vault write -address=http://<IP>:8200 -f transit/keys/autounseal 
Success! Data written to: transit/keys/autounseal

$ vault policy write -address=http://<IP>:8200 autounseal /root/autounseal.hcl 
Success! Uploaded policy: autounseal

$ vault token create -address=http://<IP>:8200 -policy="autounseal" -wrap-ttl=24h
Key                              Value
---                              -----
wrapping_token:                  s.newtoken
wrapping_accessor:               REDACTED
wrapping_token_ttl:              24h
wrapping_token_creation_time:    2021-05-29 13:52:13.743971005 +0000 UTC
wrapping_token_creation_path:    auth/token/create
wrapped_accessor:                REDACTED
```

This new token ```s.newtoken``` can be used to unseal the cluster nodes. A new token must be generated for each node in the cluster.

## Cluster leader node using raft storage
To unseal a cluster leader, make use of a wrapped key generated on the unseal node. Pass it in with ```-E UNSEALTOKEN=<wrapped token>```

Once running, you can login and run the script ```/root/cli-vault-auto-login.sh``` to automatically login to vault in the CLI and return a token for use in additional vault instances, in addition to an unseal token.

To generate a token for PKI, run ```pot term vault-clone``` and then ```/root/issue-pki-token.sh```.

## Cluster follower follower using raft storage
To unseal a cluster follower, make use of a wrapped key generated on the unseal node. Pass it in with ```-E UNSEALTOKEN=<wrapped token>```

A leader node should already exist, and must be passed in with the parameter ```-E VAULTLEADER=<IP>```.

A leader token is also required and must be passed in with the parameter ```-E LEADERTOKEN=<login token from unsealed leader>```. You can get this token from ```/root/cli-vault-auto-login.sh``` on the leader.

The cluster node will be automatically unsealed and join the cluster. Repeat for all additional nodes in the vault cluster.

## Deafult cluster usage
This cluster will generate, issue, renew certificates. 

## Other example cluster usage
This cluster can then be used as a kv store.

```
vault secrets enable -address=http://<IP>:8200 -path=kv kv-v2
vault kv -address=http://<IP>:8200 put kv/testkey webapp=TESTKEY
vault kv -address=http://<IP>:8200 get kv/testkey
```