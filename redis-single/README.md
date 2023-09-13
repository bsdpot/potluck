---
author: "Stephan Lichtenauer, Bretton Vine"
title: Redis-Single
summary: Redis is an in-memory data structure store used as a database, cache, message broker, and streaming engine.
tags: ["redis", "database", "mastodon"]
---

# Overview

This is a Redis jail intended to be run as a single Redis instance and can be started with ```pot```.

The jail exposes parameters that can either be set via the environment.

It also contains `node_exporter` and a local `consul` agent instance to be
available that it can connect to (see configuration below). You can e.g.
use the [consul](https://potluck.honeyguide.net/blog/consul/) `pot` flavour
on this site to run `consul`.

# Setup

Redis is designed to be accessed by trusted clients inside trusted environments.

This jail must be run with a non-routable IP address, accessible only to the internal network.

An optional password can provide an additional level of access control.

## Installation

* Create a ZFS data set on the parent system beforehand
  ```
  zfs create -o mountpoint=/mnt/redisdata zroot/redisdata
  ```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```
  pot mount-in -p <jailname> -m /mnt -d /mnt/redisdata
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
   -E DATACENTER=<datacenter name> \
   -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
   -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
   -E NODENAME=<name of node> \
   -E IP=<IP address> \
   [ -E AUTHPASS=<authorization password> ] \
   [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```

The DATACENTER parameter is the name of the datacenter.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent.

The NODENAME parameter is the name of the node.

The IP parameter is the IP address of this image.

AUTHPASS is an optional parameter to enable a password for client access. Client's must authenticate with this password to make use of the redis instance.

REMOTELOG is an optional parameter for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

## Usage

To be added