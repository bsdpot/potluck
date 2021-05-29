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
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> -E CONSULSERVERS=<correctly-quoted-array-consul-IPs> -E IP=<IP address of this vault node> -E VAULTTYPE=<unseal or cluster> [-E GOSSIPKEY=<32 byte Base64 key from consul keygen> -E UNSEALIP=<unseal vault node>]```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

# Architecture
* vault-unseal: is initialized and unsealed. The root token creates a transit key that enables the other Vaults auto-unseal. This Vault server is not a part of the cluster.
* vault-clone-1: is initialized and unsealed. This Vault starts as the cluster leader. A K/V-V2 secret is created.
* vault-clone-2: is only started. You will join it to the cluster.
* vault-clone-3: is only started. You will join it to the cluster.

# Usage

```vault``` is then running on port 8200 of your jail IP address.

## Unseal Node
This vault instance exists to generate unseal keys. It must first be initialised.

(This stage of the image doesn't yet include HTTPS. Please include the parameter ```-address=http://<IP>:8200``` to any ```vault``` commands```)

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

$ vault token create -address=http://<IP>:8200 -policy="autounseal" -wrap-ttl=1h
Key                              Value
---                              -----
wrapping_token:                  s.newtoken
wrapping_accessor:               REDACTED
wrapping_token_ttl:              1h
wrapping_token_creation_time:    2021-05-29 13:52:13.743971005 +0000 UTC
wrapping_token_creation_path:    auth/token/create
wrapped_accessor:                REDACTED
```

This new token ```s.newtoken``` can be used to unseal the cluster nodes. A new token must be generated for each node in the cluster.

## Cluster Node using raft storage
This is still a work in progress.

To unseal a cluster node, make use of the wrapped key generated on the unseal node:

```
$ vault unwrap -address=http://<IP>:8200 "s.newtoken"

(get new token)

$ vault login -address=http://<IP>:8200

(use new token)
```

And the cluster node will be automatically unsealed. Repeat for 3 or 5 nodes in the vault cluster.

(To do: add steps to initiate raft cluster, or join the cluster)