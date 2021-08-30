---
author: "Bretton Vine"
title: Saltstack 
summary: SaltStack, also known as Salt, is a configuration management and orchestration tool.
tags: ["saltstack", "configuration management" ]
---

# Overview

This is a flavour containing the ```salt``` security storage platform.

The flavour expects a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. If no ```consul``` instance is available at first, make sure it's up within an hour and the certificate renewal process will restart ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* [cluster node] Create a ZFS data set on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/saltdata zroot/saltdata```
* Create your local jail from the image or the flavour files. 
* Mount in the ZFS data set you created:    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/saltdata```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
  -E IP=<IP address of this node> -E STATEPATH=/mnt/salt/state -E PILLARPATH=/mnt/salt/pillar \
  -E CONSULSERVERS=<correctly-quoted-array-consul-IPs> \
  -E SSHUSER=<username> [-E REMOTELOG=<remote syslog IP>]
  ```    

The STATEPATH and PILLARPATH variables are locations of mounted-in persistent storage, ideally /mnt/salt/state and /mnt/salt/pillar.

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to, such as for the ```loki``` flavour on this site.

The SSSHUSER parameter is used to create a user with SSH keys for remote access.

The SSHPORT parameter is to custom set the port SSH runs on. It defaults to port 7777 which is not a standard SSH port.

# Usage

SSH to host and run ```salt``` commands:
```
• salt-key -L                                       :: List minions
• salt-key -A -y                                    :: Register new minions after the minion service has been started 
• salt '*' test.ping                                :: Test all minions
• salt 'minion.intra.domain.org' cmd.run 'uname -r' :: Run command on a minion
• salt '*' state.highstate                          :: Apply high state to all minions
```