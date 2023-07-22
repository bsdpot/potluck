---
author: "Stephan Lichtenauer, Bretton Vine, Michael Gmelin"
title: MariaDB (Server)
summary: MariaDB is a database server derived from (and largely compatible with) MySQL.
tags: ["mariadb", "mysql", "database", "sql"]
---

# Overview

This is a flavour containing the ```mariadb``` database server.

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
  ```pot export-ports -p <jailname> -e 3306:3306 -e 9104:9104```
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
    [ -E DUMPSCHEDULE="<cronschedule>" -E DUMPUSER=<backupuser> -E DUMPFILE=</insidejail/dumpfile.sql> ] \
    [ -E REMOTELOG=<IP address of syslog-ng server> ]
  ```
* Optionally copy-in your own server.cnf file:
  ```
  pot copy-in -p <jailname> -s <host/configdirectory/>server.cnf -d /usr/local/etc/mysql/conf.d/server.cnf
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

## Optional Parameters

DUMPSCHEDULE is a cron schedule is in the scheduling format of crontab, e.g. "*/5 * * * *". (include quotes)

DUMPUSER defaults to ```root``` and DUMPFILE defaults to ```/var/db/mysql/full_mariadb_backup.sql``` if you set a DUMPSCHEDULE but do not specify one or both of these parameters.

REMOTELOG is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

You can connect to the database server with a ```mariadb``` client according to the configuration you have copied in (or the default ```mariadb``` configuration).

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