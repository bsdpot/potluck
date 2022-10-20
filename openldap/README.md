---
author: "Bretton Vine"
title: Openldap
summary: openldap in single or multiserver mode
tags: ["ldap", "openldap", "directory services"]
---

# Overview

This is an OpenLDAP jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

It is running `openldap24-server` and not `openldap25-server`! The various `slap*` binaries exist in
`openldap24-server` only.

The jail exposes parameters that can either be set via the environment or by setting the ```cook```parameters (the
latter either via ```nomad```, see example below, or by editing the downloaded jails ```pot.conf``` file):

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

# Setup

## Prerequisites

If you wish to import an existing `openldap` database, run the following on your existing `openldap` server to
export the config and schema:
``` slapcat -n 0 -l config.ldif ```

Then edit config.ldif so that:
```
olcDbDirectory: /var/db/openldap-data
```

becomes
```
olcDbDirectory: /mnt/openldap-data
```

Then run the following to export your data entries
```
slapcat -n 1 -l data.ldif
```

Then copy these files in on pot startup as outlined below. They aren't automatically imported to `openldap`, you
need to do this manually ONLY ONCE to import data to the persistent storage you've mounted in.

Thereafter these files will load automatically, along with any updates, from persistent storage.

## Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/openldap-data zroot/openldap-data```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/openldap-data```
* Optional: Copy in YOUR config.ldif file if importing config:
  ```pot copy-in -p <jailname> -s /path/to/config.ldif -d /root/config.ldif```
* Optional: Copy in YOUR data.ldif file if importing existing data:
  ```pot copy-in -p <jailname> -s /path/to/data.ldif -d /root/data.ldif```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
  -E NODENAME=name \
  -E DATACENTER=<datacenter> \
  -E CONSULSERVERS='"1.2.3.4"' \
  -E GOSSIPKEY=<key> \
  -E IP=<IP address> \
  -E DOMAIN=<domain name> \
  -E MYCREDS=<openldap root pass> \
  -E HOSTNAME=<hostname> \
  [ -E IMPORTCUSTOM=1 ] \
  [ -E REMOTEIP=<IP address second instance> ] \
  [ -E SERVERID=<001 or 002> ] \
  [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```

The NODENAME parameter is the name of the node.

The DATACENTER parameter is the name of the datacenter. The REGION parameter is to set "east" or "west" or "global" (default).

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if the parameter is not set, do not use the default key for production encryption, instead provide your own. This key is also used as Nomad's gossipkey. 

The IP parameter is the IP address of this image.

The DOMAIN parameter is the domain name to use for `openldap` configuration.

The MYCREDS parameter is the administrator password for openldap.

The HOSTNAME is the hostname to be used.

If set, IMPORTCUSTOM enables the import of copied-in files `/root/config.ldif` and `/root/data.ldif` as a repeat in the cook script. Also available via shell scripts.

The optional REMOTEIP parameter is the IP address of a second `openldap` pot server if running a multi-master
cluster. If set, a cluster setup will be initiated.

The optional SERVERID parameter is one of `001` or `002` for first or second server if running a multi-master cluster.

The optional REMOTELOG parameter is for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

# Usage

## Importing old data

Once started, a basic `openldap` configuration will be setup with data structures configured in `/mnt/openldap-data`.

You can import your copied-in backup config.ldif files as follows for the configuration, database 0:
```
/root/importldapconfig.sh
```

This is the same as running:
```
/usr/local/sbin/slapadd -c -n 0 -F /usr/local/etc/openldap/slapd.d/ -l /root/config.ldif
```

You can import your copied-in data.ldif files as follows, for database 2:
```
/root/importldapdata.sh
```

This is the same as running:
```
/usr/local/sbin/slapadd -c -n 1 -F /usr/local/etc/openldap/slapd.d/ -l /root/data.ldif
```

There may be errors on import, but the `-c` flag continues regardless of errors.

Check the resulting import for any missing data. It's possible you may have to add missing entries.

Important: `ldapmodify` and `ldapadd` don't work for import, where `slapadd` works with some errors in most cases.

## Two server setup - multi-master cluster

When running with two servers, you must first setup one and import existing data with the included scripts.

Then start a second server on a different host (both will use /mnt/openldap-data so keep on different servers)
with a different SERVERID and setting REMOTEIP to the IP address of the first server.

## Basic command line search

Check entries in your `openldap` database by running an anonymous search (no auth):
```
ldapsearch -x -b "dc=your-domain,dc=net"
```

## LAM web frontend
Open http://yourhost to access the LAM `openldap` web frontend.
