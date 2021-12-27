---
author: "Stephan Lichtenauer, Bretton Vine, Michael Gmelin"
title: Consul-TLS
summary: Consul-tls is a service discovery platform for micro-services integrated with Vault.
tags: ["micro-services", "vault", "nomad", "consul"]
---

# Overview

This is a flavour containing the ```consul``` service discovery platform, configured for PKI certificates  via ```Vault```.

Together with the [nomad-server](https://potluck.honeyguide.net/blog/nomad-server/) and the [traefik](https://potluck.honeyguide.net/blog/traefik-consul/) ```pot``` flavours on this site, you can easily set up a virtual datacenter.

# Installation

* [Optional] Create a ZFS dataset on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/consul zroot/consul```
* Create your local jail from the image or the flavour files. 
* [Optional] Mount in the ZFS dataset you created:    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/consul```
* Copy in the SSH private key for the user on the Vault leader:    
  ```pot copy-in -p <jailname> -s /root/sshkey -d /root/sshkey```
* Export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8500:8500```   
  Note: If you want to use the ```consul``` DNS service, you either need to expose the DNS UDP port like for the [Jitsi Meet Nomad potluck image](https://potluck.honeyguide.net/blog/jitsi-meet-nomad/) or you need to clone the jail and assign a host IP address (like for the [Nomad Server image](https://potluck.honeyguide.net/blog/nomad-server/)).
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<consul-nodename> -E IP=<IP address of this consul node> \
  -E BOOTSTRAP=<1|3|5> -E VAULTSERVER=<IP address of a vault server> -E VAULTTOKEN=<pki token> \
   -E SFTPUSER=<user> -E SFTPPASS=<password> \
   -E GOSSIPKEY=<32 byte Base64 consul keygen key> -E REMOTELOG=<remote syslog IP>```

The BOOTSTRAP parameter defines the expected number of ```consul``` cluster nodes, it defaults to 1 (no cluster) if it is not set.

For 3 and 5 node clusters the other ```consul``` peers must be passed in via the PEERS variable in the following format:
```-E IP=10.0.0.1 -E PEERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5"'```

The VAULTSERVER parameter is for the IP address of the ```vault``` leader server.

The VAULTTOKEN parameter is for an issued token with permissions to obtain certificates from the ```vault``` cluster.

The GOSSIPKEY parameter is to enable custom gossip encryption and defaults to a standard key. Do not use this key in production.

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to, such as for the ```loki``` flavour on this site.

The SFTPUSER and SFTPPASS parameters are for the user on the ```vault``` leader in the VAULTSERVER parameter. You need to copy in the id_rsa from there to the host of this image.

(new info to be included, docs require update)
The ATTL and BTTL parameters are 2 lengths of time for certificate TTL, where BTTL must be longer than ATTL, eg. if ATTL is 10m, BTTL is 12m.

# Usage

You can connect to the dashboard on port 8500 of your jail IP address.
