---
author: "Bretton Vine"
title: Saltstack
summary: SaltStack, also known as Salt, is a configuration management and orchestration tool.
tags: ["saltstack", "configuration management" ]
---

# Overview

This is a flavour containing the ```salt``` configuration management and orchestration tool.

The flavour expects a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. If no ```consul``` instance is available at first, make sure it's up within an hour and the certificate renewal process will restart ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* [cluster node] Create a ZFS data set on the parent system beforehand:
  ```zfs create -o mountpoint=/mnt/saltdata zroot/saltdata```
* Create your local jail from the image or the flavour files.
* Mount in the ZFS data set you created:
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/saltdata```
* [optional] Copy in the primary keys from an existing master:
  ```
  pot copy-in -p <jailname> -s /path/to/master.pem -d /root/master.pem
  pot copy-in -p <jailname> -s /path/to/master.pub -d /root/master.pub
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
  -E DATACENTER=<datacentername> \
  -E NODENAME=<nodename> \
  -E IP=<IP address of this node> \
  -E PKIPATH="/mnt/salt/pki/master" \
  -E STATEPATH="/mnt/salt/state" \
  -E PILLARPATH="/mnt/salt/pillar" \
  -E SSHUSER=<username> \
  -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
  -E GOSSIPKEY="<32 byte Base64 key from consul keygen>" \
  [ -E REMOTELOG=<remote syslog IP> ]
  ```

The PKIPATH parameter is the location of the mounted-in persistent storage, ideally ```/mnt/salt/pki/master/```. Please quote the path.

If existing keys are copied in, they will overwrite the data in ```/mnt/salt/pki/master/```.

The STATEPATH parameter is the location of the mounted-in persistent storage for state files, ideally ```/mnt/salt/state```. Please quote the path.

The PILLARPATH parameter is the location of mounted-in persistent storage for private data, ideally ```/mnt/salt/pillar```. Please quote the path.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if the parameter is not set, do not use the default key for production encryption, instead provide your own.

The SSHUSER parameter is used to create a user with SSH keys for remote access.

The SSHPORT parameter is to custom set the port SSH runs on. It defaults to port 7777 which is not a standard SSH port.

REMOTELOG is an optional parameter for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

# Usage

SSH to host and run ```salt``` commands:
```
• salt-key -L                                       :: List minions
• salt-key -A -y                                    :: Register new minions after the minion service has been started
• salt '*' test.ping                                :: Test all minions
• salt 'minion.intra.domain.org' cmd.run 'uname -r' :: Run command on a minion
• salt '*' state.highstate                          :: Apply high state to all minions
```

# Consul DNS

Consul DNS works in the format `servicename.service.consul` or `nodename.node.consul`.

Consul DNS is integrated with local unbound in this image. You can query consul DNS like any normal DNS query directly to localhost.

To get a list of services listed in `consul` you can do the following:

```
curl -s "http://127.0.0.1:8500/v1/catalog/services" | jq
```

You can query the IP address of a service with

```
drill servicename.service.consul
```
