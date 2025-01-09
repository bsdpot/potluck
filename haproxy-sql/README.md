---
author: "Stephan Lichtenauer, Bretton Vine"
title: HAProxy-SQL
summary: HAProxy-SQL is a haproxy loadbalancer for SQL servers.
tags: ["loadbalance", "haproxy", "mariadb", "galera", "clustering" ]
---

# Overview

This is a `haproxy` jail that can be started with ```pot```.

The jail exposes parameters that can either be set via the environment.

It also contains `node_exporter` and a local `consul` agent instance to be
available that it can connect to (see configuration below). You can e.g.
use the [consul](https://potluck.honeyguide.net/blog/consul/) `pot` flavour
on this site to run `consul`.

# Setup
You must be running 2 or 3 `mariadb` servers, such as the pot mariadb images, configured for replication on all servers in a MASTER-MASTER configuration.

The `mariadb` pot images must already be started with the LOADBALANCER parameter set to the IP address of this jail. This will setup access control and allow haproxy checks from this host for the user `haproxy`.

## Installation

* Create a ZFS data set on the parent system beforehand
  ```
  zfs create -o mountpoint=/mnt/haproxysqldata zroot/haproxysqldata
  ```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```
  pot mount-in -p <jailname> -m /mnt -d /mnt/haproxysqldata
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
   -E DATACENTER=<datacenter name> \
   -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
   -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
   -E NODENAME=<name of node> \
   -E IP=<IP address> \
   -E SERVERONE=<IP address first mariadb host> \
   -E SERVERTWO=<IP address second mariadb host> \
   [ -E SERVERTHREE=<IP address this mariadb host> ] \
   [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```

The DATACENTER parameter is the name of the datacenter.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent.

The NODENAME parameter is the name of the node.

The IP parameter is the IP address of this image.

The SERVERONE parameter is the IP address of the first `mariadb` instance. It is required.

The SERVERTWO parameter is the IP address of the second `mariadb` instance. It is required.

SERVERTHREE is an optional parameter for the IP address of the third `mariadb` instance. Do not set to any value if there is no third server.

REMOTELOG is an optional parameter for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

## Usage

Configure your application database settings to use the IP address of this jail, port 3306 and the applicable `mariadb` username and password. 

This is an example of a two server MASTER-MASTER setup showing alternate `server_id` values:

```
user@host:$ mysql -h haproxy-sql.ip -u haproxy --execute="SELECT VERSION(), @@server_id"
+---------------------+-------------+
| VERSION()           | @@server_id |
+---------------------+-------------+
| 10.6.14-MariaDB-log |           2 |
+---------------------+-------------+

user@host:$ mysql -h haproxy-sql.ip -u haproxy --execute="SELECT VERSION(), @@server_id"
+---------------------+-------------+
| VERSION()           | @@server_id |
+---------------------+-------------+
| 10.6.14-MariaDB-log |           1 |
+---------------------+-------------+
```
