---
author: "Stephan Lichtenauer, Bretton Vine, Michael Gmelin"
title: MariaDB (Galera Cluster)
summary: MariaDB-Galera is a database cluster derived from (and largely compatible with) MySQL.
tags: ["mariadb", "mysql", "database", "sql", "cluster", "galera", "redundancy"]
---

# Overview

This is a flavour containing the ```mariadb``` database server with ```galera``` clustering solution enabled. It is currently WIP development image and separate from the `mariadb` image on purpose.

It is assumed that a persistent directory containing the ```mysql``` datadir is mounted in to ```/var/db/mysql```, optionally you could copy in your ```server.cnf``` configuration if you do have specific needs not covered by the default configuration (see Installation chapter below).

Also, it supports parameters to regularly dump the content of the database into a SQL-file so you can create consistent backups from outside the jail.

To ensure that software and database file versions match, ```mysql_upgrade``` is run on startup. That way, you should be able to upgrade your ```mariadb``` installation by simply replacing the jail with a newer version as long as the database files are stored outside and mounted in (see above and examples below).

# Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/mysqldata zroot/mysqldata```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```pot mount-in -p <jailname> -m /var/db/mysql -d /mnt/mysqldata```
* Optionally export the ports after creating the jail:
  ```pot export-ports -p <jailname> -e 3306:3306 -e 4567:4567 -e 4568:4568 -e 4444:4444 -e 4567:4567 -e 9104:9104```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul server IP addresses>" \
    -E GOSSIPKEY="<32 byte Base64 key from consul keygen>" \
    -E DBROOTPASS=<database root password> \
    -E DBSCRAPEPASS=<mysqld exporter user password> \
    -E SERVERID=<unique identifier 1,2,3> \
    -E GALERACLUSTER=<comma-deliminated list of all mariadb servers in cluster> \
    [ -E GALERAPRIMARY=<Y> ] \
    [ -E DUMPSCHEDULE="<cronschedule>" -E DUMPUSER=<backupuser> -E DUMPFILE=</insidejail/dumpfile.sql> ] \
    [ -E LOADBALANCER=<IP address of haproxy-sql image> ] \
    [ -E REMOTELOG=<IP address of syslog-ng server> ]
  ```

## Required Paramaters

DATACENTER defines a common datacenter.

NODENAME defines the name of this node.

IP is the IP address which will be used to access services.

CONSULSERVERS is a comma-deliminated list of consul server instances. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.6,10.0.0.6"```

GOSSIPKEY is the gossip encryption key for consul agent and must be passed in as a parameter.

DBROOTPASS is the root password for the mysql database, which must be passed in even if database exists and configured.

DBSCRAPEPASS is the password for the mysqld_exporter ```exporter``` user.

SERVERID is a unique identifier. Set to `1` for first server, `2` for second and so on.

GALERACLUSTER is a comma-deliminated list of all `mariadb` servers in the cluster.

## Optional Parameters

GALERAPRIMARY is set on the first server in the cluster. You'll launch this node first. Do not set on the others.

DUMPSCHEDULE is a cron schedule is in the scheduling format of crontab, e.g. "*/5 * * * *". (include quotes)

DUMPUSER defaults to ```root``` and DUMPFILE defaults to ```/var/db/mysql/full_mariadb_backup.sql``` if you set a DUMPSCHEDULE but do not specify one or both of these parameters.

LOADBALANCER is the IP address of a `haproxy-sql` instance which will provide loadbalancing between two or three `mariadb` instances. A user called `haproxy` is created with no password and no access to databases.

REMOTELOG is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

You can connect to the database server with a ```mariadb``` client.

## Galera Replication

Replication should be automatic between nodes once a database is added to first server.

## High Availability

You can use a loadbalancing/failover TCP proxy such as the `haproxy-sql` pot image to query all servers in the cluster. Make sure to set the LOADBALANCER variable to the IP of the `haproxy-sql` image in advance.
