---
author: "Stephan Lichtenauer, Bretton Vine"
title: Nextcloud Spreed Signalling Server
summary: The standalone signaling server which can be used for Nextcloud.
tags: ["matrix", "synapse", "im", "instant messaging", "rooms", "chat"]
---

# Overview

This is a Spreed Signalling server jail that can be started with ```pot```.

This is a non-layered image using latest pkg stream.

The jail exposes parameters that can either be set via the environment.

It also contains `node_exporter` and a local `consul` agent instance to be
available that it can connect to (see configuration below). You can e.g.
use the [consul](https://potluck.honeyguide.net/blog/consul/) `pot` flavour
on this site to run `consul`.

# Setup
You must run this instance from a top level domain such as `my.hostname.com`.

## Installation

* Create a ZFS data set on the parent system beforehand
  ```
  zfs create -o mountpoint=/mnt/spreeddata zroot/spreeddata
  ```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```
  pot mount-in -p <jailname> -m /mnt -d /mnt/spreeddata
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
   -E DATACENTER=<datacenter name> \
   -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
   -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
   -E NODENAME=<name of node> \
   -E IP=<IP address> \
   -E DOMAIN=<domain name> \
   -E EMAIL=<email address for certificate registration> \
   -E NEXTCLOUDURL=<FQDN nextcloud host, no https> \
   -E SHAREDSECRET=<shared secret with nextcloud host> \
   [ -E PVTCERT=<any value enables> ] \
   [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```

The DATACENTER parameter is the name of the datacenter.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent.

The NODENAME parameter is the name of the node.

The IP parameter is the IP address of this image.

The DOMAIN parameter is the domain name to use for `acme.sh` SSL certificate registration. It will be the same as the servername for the host.

The EMAIL parameter is the email address to use for `acme.sh` SSL certificate registration.

The NEXTCLOUDURL parameter is the FQDN of the Nextcloud instance. Do not include the `https://` bit, only the FQDN.

The SHAREDSECRET parameter is the shared secret with the Nextcloud instance. This must be 32 characters in hex format.

The PVTCERT parameter will enable self-signed certificates instead of obtaining from provider.

REMOTELOG is an optional parameter for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

## Usage

### Configure Nextcloud Talk

From the git repo for the `nextcloud-spreed-signaling` package, https://github.com/strukturag/nextcloud-spreed-signaling

```
Setup of Nextcloud Talk

Login to your Nextcloud as admin and open the additional settings page. Scroll down to the "Talk" section and enter the base URL of your standalone signaling server in the field "External signaling server". Please note that you have to use https if your Nextcloud is also running on https. Usually you should enter https://my.hostname.com/standalone-signaling as URL.

The value "Shared secret for external signaling server" must be the same as the property secret in section backend of your server.conf.

If you are using a self-signed certificate for development, you need to uncheck the box Validate SSL certificate so backend requests from Nextcloud to the signaling server can be performed.
```