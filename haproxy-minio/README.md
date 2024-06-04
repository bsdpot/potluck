---
author: "Stephan Lichtenauer, Bretton Vine"
title: HAProxy-Minio
summary: HAProxy-Minio is a haproxy loadbalancer for Minio servers.
tags: ["loadbalance", "haproxy", "minio", "clustering" ]
---

# Overview

This is a `haproxy` jail that can be started with ```pot```.

The jail exposes parameters that can either be set via the environment.

It also contains `node_exporter` and a local `consul` agent instance to be
available that it can connect to (see configuration below). You can e.g.
use the [consul](https://potluck.honeyguide.net/blog/consul/) `pot` flavour
on this site to run `consul`.

# Setup
You must be running 1 to 4 `minio` servers.

## Installation

* Create a ZFS data set on the parent system beforehand
  ```
  zfs create -o mountpoint=/mnt/haproxyminiodata zroot/haproxyminiodata
  ```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```
  pot mount-in -p <jailname> -m /mnt -d /mnt/haproxyminiodata
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
   -E DATACENTER=<datacenter name> \
   -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
   -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
   -E NODENAME=<name of node> \
   -E IP=<IP address> \
   -E DOMAIN=<internal domain name for self-signed certificate> \
   -E SERVERONE=<IP address first minio host> \
   -E SERVERONEPORT=<port> \
   [ -E SERVERTWO=<IP address second minio host> ] \
   [ -E SERVERTWOPORT=<port> ] \
   [ -E SERVERTHREE=<IP address third minio host> ] \
   [ -E SERVERTHREEPORT=<port> ] \
   [ -E SERVERFOUR=<IP address third minio host> ] \
   [ -E SERVERFOURPORT=<port> ] \
   [ -E SELFSIGNHOST=<any value enables> ] \
   [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```

The DATACENTER parameter is the name of the datacenter.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent.

The NODENAME parameter is the name of the node.

The IP parameter is the IP address of this image.

The DOMAIN parameter is the internal domain name for the host to generate a self-signed certificate for `haproxy`.

The SERVERONE parameter is the IP address of the first `minio` instance. It is required.

The SERVERONEPORT parameter is the port of the first `minio` instance. Commonly `9000`.

SERVERTWO is an optional parameter is the IP address of the second `minio` instance.

SERVERTWOPORT is an optional parameter is the port of the second `minio` instance. Commonly `9000`.

SERVERTHREE is an optional parameter for the IP address of the third `minio` instance. Do not set to any value if there is no third server.

SERVERTHREEPORT is an optional parameter is the port of the third `minio` instance. Commonly `9000`.

SERVERFOUR is an optional parameter for the IP address of the fourth `minio` instance. Do not set to any value if there is no fourth server.

SERVERFOURPORT is an optional parameter is the port of the fourth `minio` instance. Commonly `9000`.

SELFSIGNHOST is an optional parameter to retrieve certificates from self-signed `minio` servers using SERVERONE and saving to local certificate store.

REMOTELOG is an optional parameter for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

## Usage

This pot jail exposes HTTPS minio on both HTTP and HTTPS. 

It should not be run on a public IP unless you want HTTP access to your minio setup.

This might not be the right pot jail for your minio loadbalancing needs. You might want to remove the HTTP proxy.
