---
author: "Stephan Lichtenauer & Bretton Vine"
title: Nomad (Server) TLS
summary: Nomad is a scalable orchestration tool to run jobs on many hosts.
tags: ["micro-services", "traefik", "nomad", "consul"]
---

# Overview

This is a flavour containing the ```nomad``` service orchestrator with TLS encryption. You need a running Vault instance/cluster to make this work.

This flavour is configured as orchestration server. You need one or more ```nomad``` client instances that connect to this server and actually run the workload.

Since clients need to run jobs e.g. via ```pot```, you need to install the client directly on a host; therefore you will not find a ```nomad``` client flavour on potluck.

Together with [consul](https://potluck.honeyguide.net/blog/consul/) and the [traefik](https://potluck.honeyguide.net/blog/traefik-consul/) ```pot``` flavours on this site, you can easily set up a virtual datacenter.

Please note that a specific network configuration is suggested (see Installation-chapter) as this jail does not work behind the NAT of a public-bridge.

# Installation
* [Optional] Create a ZFS dataset on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/nomad zroot/nomad```
* Create your local jail from the image or the flavour files. 
* [Optional] Mount in the ZFS dataset you created:    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/nomad```
* Create your local jail from the image or the flavour files. 
* This jail does not work with a public bridge, so clone it to use an IP address directly on your host:     
  ```sudo pot clone -P <nameofimportedjail> -p <clonejailname> -N alias -i "<interface>|<ipaddress>"```   
  e.g.
  ```sudo pot clone -P nomad-server-amd64-13_2_0_2 -p my-nomad-server -N alias -i "em0|10.10.10.11"```   
* Adjust to your environment:    
  ```sudo pot set-env -p <clonejailname> -E DATACENTER=<datacentername> -E NODENAME=<name of this node> -E IP=<IP address of this nomad instance> -E CONSULSERVERS=<'"list", "of", "consul", "IPs"'> [-E BOOTSTRAP=<1|3|5>] [-E GOSSIPKEY=<32 byte Base64 key from consul keygen>] [-E NOMADKEY=<16 byte or 32 byte key from nomad operator keygen>]
  [-E VAULTSERVER=<IP of Vault>] [-E VAULTTOKEN=<token-issued-by-vault>] [-E REMOTELOG=<remote syslog IP>]```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The VAULTSERVER parameter defines the master Vault server to authenticate against, and can be passed in as an IP address.

The VAULTTOKEN parameter is a required valid token from the Vault service.

The BOOTSTRAP parameter defines the expected number of cluster nodes, it defaults to 1 (no cluster) if it is not set. You MUST still pass in a consul IP under CONSULSERVERS.

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if the parameter is not set, do not use the default key for production encryption, instead provide your own.

The NOMADKEY parameter is the gossip encryption key for nomad. We're re-using the default key from consul as nomad supports 32 byte Base64 keys, but the common one is a 16 byte Bas64 key from ```nomad operator keygen```

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to, such as for the ```loki``` flavour on this site.

# Usage

You can connect to the dashboard on port 4646 of your jail IP address.

To run a new job, connect to the jail via ```pot term <jailname>``` and run a ```nomad``` job description via ```nomad run -address=http://<jailip>:4646 <jobfile>``` or place the job via the dashboard.
