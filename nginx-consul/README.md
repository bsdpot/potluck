---
author: "Bretton Vine, Michael Gmelin"
title: nginx-Consul 
summary: nginx-consul is a consul-integrated web server
tags: ["web", "proxy", "nginx", "consul"]
---

# Overview

This is a flavour containing the `nginx` load-balancing proxy with
`consul` integration.

Please copy in your own `nginx.conf` file, the default setup is
hard-coded example.

The flavour includes a local `consul` agent instance to be available that it
can connect to (see configuration below).  You can e.g.  use the
[consul](https://potluck.honeyguide.net/blog/consul/) `pot` flavour on this
site to run `consul`.  If no `consul` instance is available at first, make
sure it's up within an hour and the certificate renewal process will restart
`consul`.  You can also connect to this host and `service consul restart`
manually.

# Installation

* Create a ZFS data set on the parent system beforehand
  `zfs create -o mountpoint=/mnt/nginxdata zroot/nginxdata`
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS data set you created
  `pot mount-in -p <jailname> -m /mnt -d /mnt/nginxdata`
* Place your nginx.conf.in in that path
* Adjust to your environment:    

  sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
  -E IP=<IP address of this system> \
  -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
  -E VAULTSERVER=<IP address vault server> -E SERVERNAME=server_name
  [-E DNSFORWARDERS=<none|list of IPs>]

The CONSULSERVERS parameter defines the consul server instances, and must be
set as
* `CONSULSERVERS='"10.0.0.2"'` or
* `CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'` or
* `CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'`

The VAULTSERVER parameter is the IP address of the `vault` server to
authenticate to, and obtain certificates from.

SERVERNAME is used in the server certificates SubjectAltName.

The DNSFORWARDERS parameter is a space delimited list of IPs to forward DNS
requests to. If set to `none` or left out, no DNS forwarders are used.

# Usage

To configure `nginx`you must copy-in a `nginx.conf` file with your specific
front-end and back-end parameters.

If you don't copy-in your own `nginx.conf` file, then please take note the
default is a webserver listening to localhost.

# Persistent Storage
Persistent storage will be in the ZFS data set zroot/nginxdata, available
inside the image at /mnt

If you stop the image, the data will still exist, and a new image can be
started up and still use it.

If you need to change the directory parameters for the ZFS data set, adjust
the `mount-in` command accordingly for the source directory as mounted by
the parent OS.

Do not adjust the image destination mount point at /mnt because `nginx` is
configured to use this directory for data.
