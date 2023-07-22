---
author: "Bretton Vine"
title: Openldap
summary: openldap in single or multiserver mode
tags: ["ldap", "openldap", "directory services"]
---

# Overview

This is an OpenLDAP jail that can be started with ```pot```.

The jail exposes parameters that can be set via the environment with `pot set-env` parameters below.

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

* Create a ZFS data set on the parent system beforehand, for example:
  ```
  zfs create -o mountpoint=/mnt/openldap root/openldap
  ```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```
  pot mount-in -p <jailname> -d /mnt/openldap -m /mnt
  ```
* Optional: Copy in YOUR config.ldif file if importing an existing config:
  ```
  pot copy-in -p <jailname> -s /path/to/config.ldif -d /root/config.ldif
  ```
* Optional: Copy in YOUR data.ldif file if importing existing data:
  ```
  pot copy-in -p <jailname> -s /path/to/data.ldif -d /root/data.ldif
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
  -E NODENAME=name \
  -E DATACENTER=<datacenter> \
  -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
  -E GOSSIPKEY="<key>" \
  -E IP=<IP address> \
  -E DOMAIN="<domain name>" \
  -E MYCREDS=<openldap root pass> \
  -E HOSTNAME=<hostname> \
  [ -E CRONBACKUP=/mnt/openldap-data/backups ] \
  [ -E IMPORTCUSTOM=1 ] \
  [ -E REMOTEIP=<IP address second instance> ] \
  [ -E SERVERID=<001 or 002> ] \
  [ -E DEFAULTGROUPS=Y ] \
  [ -E USERNAME=<generic user username> ] \
  [ -E PASSWORD=<generic user password ] \
  [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```

The NODENAME parameter is the name of the node.

The DATACENTER parameter is the name of the datacenter.

The CONSULSERVERS parameter is a comma-deliminated list of consul servers. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent.

The IP parameter is the IP address of this image.

The DOMAIN parameter is the domain name to use for `openldap` configuration.

The MYCREDS parameter is the administrator password for openldap.

The HOSTNAME is the hostname to be used.

The CRONBACKUP parameter is the path to persistent storage where automatic backups of ldap config and data are dropped.

If set, IMPORTCUSTOM enables the import of copied-in files `/root/config.ldif` and `/root/data.ldif` as a repeat in the cook script. Also available via shell scripts.

The optional REMOTEIP parameter is the IP address of a second `openldap` pot server if running a multi-master
cluster. If set, a cluster setup will be initiated.

The optional SERVERID parameter is one of `001` or `002` for first or second server if running a multi-master cluster.

The optional DEFAULTGROUPS parameter will enable a default group arrangement with People and mail, if set to any value. This will not work if IMPORTCUSTOM is enabled.

The optional USERNAME and PASSWORD parameters will setup a generic user if DEFAULTGROUPS is also enabled. If not passed in, no generic user will be created, but the groups will be. No mail value is assigned to the generic user and can be set manually. This will not work if IMPORTCUSTOM is enabled.

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

Or with authenticated search:
```
ldapsearch -x -LLL -b "dc=your-domain,dc=net" -W
Enter LDAP Password:

ldapsearch -x -LLL -D cn=Manager,dc=your-domain,dc=net -W
Enter LDAP Password:

ldapsearch -x -LLL -D cn=Manager,dc=your-domain,dc=net -W -H ldap://1.2.3.4
Enter LDAP Password:
```

## LAM web frontend
Open http://yourhost to access the LAM `openldap` web frontend.

## Updating Master password
It's possible to update the master password on imported ldif files, however to avoid a checksum error extra steps required.

First copy `/usr/local/etc/openldap/slapd.d/cn=config/olcDatabase={1}mdb.ldif` to a temporary file:
```
cp "/usr/local/etc/openldap/slapd.d/cn=config/olcDatabase={1}mdb.ldif" /tmp/stepone.ldif
```

Then generate a password with the `slappasswd` tool as follows:
```
slappasswd -s newPassword
```

For example:
```
slappasswd -s lam
{SSHA}A6feTpxMvW6YWuMka4aK64jUr18hRvvJ
```

Then edit `/tmp/stepone.ldif` and change the line `olcRootPW:: OldPasswordString` to the string you get from `slappasswd`:
```
olcRootPW: {SSHA}A6feTpxMvW6YWuMka4aK64jUr18hRvvJ
```

Remove the first two lines where it says:
```
# AUTO-GENERATED FILE - DO NOT EDIT!! Use ldapmodify.
# CRC32 XXXXXXX
```

Save the file. Now calculate a new checksum value with `rhash` tool:
```
rhash -C /tmp/stepone.ldif
```

Then update the file with the correct hash value by inserting at the top:
```
# AUTO-GENERATED FILE - DO NOT EDIT!! Use ldapmodify.
# CRC32 nEwHaSh
```

Then make a backup old file, and copy over adjusted file, and restart `slapd`:
```
cd "/usr/local/etc/openldap/slapd.d/cn=config/"
cp "olcDatabase={1}mdb.ldif" backup.ldif
cp /tmp/stepone.ldif "olcDatabase={1}mdb.ldif"
service slapd restart
```

You can now login as Manager via web front end with the new credentials.

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
