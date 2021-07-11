---
author: "Bretton Vine"
title: Patroni PostgreSQL
summary: This is a PostgreSQL server jail that supports redundancy via Patroni.
tags: ["postgresql", "patroni", "sql", "database"]
---

# Overview

This is a ```patroni postgresql``` jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

The jail exposes these parameters that can either be set via the environment or by setting the ```cook```parameters (the latter either via ```nomad```, see example below, or by editing the downloaded jails ```pot.conf``` file):

# Installation
* Create a ZFS dataset on the parent system beforehand:    
  ```zfs create -o mountpoint=/mnt/postgresqldata zroot/postgresqldata```
* Create your local jail from the image or the flavour files. 
* Mount in the ZFS dataset you created:    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/postgresqldata```
* Optionally export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 5432:5432```    
* Adjust to your environment:    
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> -E IP=<IP address of this node> \
     -E SERVICETAG=<master/replica/standby-leader> -E CONSULSERVERS=<correctly-quoted-array-consul-IPs> \
     -E VAULTSERVER=<Vault leader IP> -E VAULTTOKEN=<s.token> -E REMOTELOG=<IP of loki> \
     [-E ADMPASS=<custom admin password> -E KEKPASS=<custom postgresql superuser password> -E REPPASS=<custom replication password>] \
     [-E GOSSIPKEY=<32 byte Base64 key from consul keygen>]```

The SERVICETAG parameter defines if this is a master, replica or standby-leader node in the cluster,

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The VAULTSERVER parameter is the IP address of the ```vault``` server to authenticate to, and obtain certificates from.

The VAULTTOKEN parameter is the issued token from the ```vault``` server.

The ADMPASS parameter is the admin user password which defaults to `admin`.

The KEKPASS parameter is the superuser password for postgres, which dfaults to `kekpass`.

The REPPASS parameter is the relicator user password, for replication purposes, and defaults to `reppass`.

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to, such as for the ```loki``` flavour on this site.

# Usage

The mount-in dataset goes to /mnt. This change from /var/db/postgres requires the ```postgres``` user's home directory be updated from the default to this. This is done automatically and will work as long as the mount-in directory is /mnt.

You must su to the postgresql user and run psql to interact with Postgresql. 

No default database exists. It will have to be setup or imported.

Verify node or cluster details with

```
curl -s http://localhost:8008/patroni | jq .

curl -s http://localhost:8008/cluster | jq .

/usr/local/etc/rc.d/patroni list
```

# Starting over

If you need to reset the cluster, and start from scratch, make sure to remove the kv values in ```consul```. If you don't the old data will simply be imported to the new cluster.
