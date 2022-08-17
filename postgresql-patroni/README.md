---
author: "Stephan Lichtenauer, Bretton Vine, Michael Gmelin"
title: Patroni PostgreSQL
summary: This is a PostgreSQL server jail that supports redundancy via Patroni.
tags: ["postgresql", "patroni", "sql", "database"]
---

# Overview

This is a `patroni postgresql` jail that can be started with `pot`.

The jail exposes these parameters that can either be set via the environment
or by setting the `cook`parameters (or by editing the downloaded jails
`pot.conf` file):

It is dependent on a `consul` server/cluster for the DCS store.

# Installation
* Create a ZFS data set on the parent system beforehand:
  `zfs create -o mountpoint=/mnt/postgresqldata zroot/postgresqldata`
* Create your local jail from the image or the flavour files.
* Mount in the ZFS data set you created:
  `pot mount-in -p <jailname> -m /mnt -d /mnt/postgresqldata`
* Copy in the SSH private key for the user on the Vault leader:
  `pot copy-in -p <jailname> -s /root/sshkey -d /root/sshkey`
* Optionally export the ports after creating the jail:
  `pot export-ports -p <jailname> -e 5432:5432`
* Adjust to your environment:    

      sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> \
        -E NODENAME=<nodename> -E IP=<IP address of this node> \
        -E SERVICETAG=<master/replica/standby-leader> \
        -E CONSULSERVERS=<correctly-quoted-array-consul-IPs> \
        -E REMOTELOG=<IP of loki> [-E DNSFORWARDERS=<none|list of IPs>]

The SERVICETAG parameter defines if this is `master`, `replica`, or
standby-leader node in the cluster.

The CONSULSERVERS parameter defines the consul server instances, and must be
set as
* `CONSULSERVERS='"10.0.0.2"'` or
* `CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'` or
* `CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'`

The REMOTELOG parameter is the IP address of a remote syslog server to send
logs to, such as for the `loki` flavour on this site.

The DNSFORWARDERS parameter is a space delimited list of IPs to forward DNS
requests to. If set to `none` or left out, no DNS forwarders are used.

To be documented: Booting the image the first time requires placing
various credentials in /mnt/postgrescerts.

# Usage

Usage notes
* The mount-in data set goes to /mnt. This change from /var/db/postgres
  requires the `postgres` user's home directory be updated from the default
  to this.  This is done automatically and will work as long as the mount-in
  directory is /mnt.
* You must su to the postgresql user and run psql to interact with
  PostgreSQL.
* No default database exists. It will have to be setup or imported.

Verify node or cluster details with

    # checks https://localhost:8008/patroni
    /root/verifynode.sh
    # checks https://localhost:8008/cluster
    /root/verifycluster.sh
    /usr/local/etc/rc.d/patroni list

# Starting over

If you need to reset the cluster, and start from scratch, make sure to
remove the kv values in `consul`. If you don't the old data will simply be
imported to the new cluster.
