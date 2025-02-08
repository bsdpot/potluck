---
author: "Bretton Vine"
title: Unison-SSH
summary: Unison-SSH is a pot image with unison for a single user with SSH access via key
tags: ["unison", "file synchronisation", "ssh"]
---

# Overview

This flavour currently contains ```unison``` for synchronising two directories, with SSH.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Create a ZFS dataset beforehand:
  ```zfs create -o mountpoint=/mnt/jaildata/unison zroot/jaildata/unison```
* Create your local jail from the image or the flavour files.
* Mount in the ZFS data set you created as follows:
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/jaildata/unison```
* Copy in the `authorized_keys` file for the `unison` user to `/root/importauthkey` specifically:
  ```pot copy-in -p <jailname> -s /path/to/authorized_keys -d /root/importauthkey```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
  -E DATACENTER=<datacentername> \
  -E NODENAME=<nodename> \
  -E IP=<IP address of this node> \
  -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
  -E GOSSIPKEY="<32 byte Base64 key from consul keygen>" \
  [ -E SSHPORT=<alternative port for SSH> ] \
  [ -E REMOTELOG=<remote syslog IP> ]
  ```
* Start the jail

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

## Optional Parameters

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

The SSHPORT parameter is for changing the SSH port from the default 22.

# Usage

From client side with `unison` installed, over VPN with access to applicable internal pot IP address:

```
unison -batch dir1 ssh://unison@10.0.0.10/unisondata/dir1
```
