---
author: "Stephan Lichtenauer"
title: MariaDB (Server)
summary: MariaDB is a database server derived from (and largely compatible with) MySQL.
tags: ["mariadb", "mysql", "database", "sql"]
---

# Overview

This is a flavour containing the ```mariadb``` database server.

It is assumed that a persistent directory containing the ```/var/db/mysql``` files is mounted in, optionally you could copy in your ```server.cnf``` configuration if you do have specific needs not covered by the default configuration (see Installation chapter below).

Also, it supports parameters to regularly dump the content of the database into a SQL-file so you can create consistent backups from outside the jail.

To ensure that software and database file versions match, ```mysql_upgrade``` is run on startup. That way, you should be able to upgrade your ```mariadb``` installation by simply replacing the jail with a newer version as long as the database files are stored outside and mounted in (see above and examples below).

# Installation

* Create your local jail from the image or the flavour files. 
* If you want to automatically create database dumps for consistent backups from outside the jail, adjust to your environment:    
    Optional but advisable: ```pot mount-in -p <mariadbjailname> -d </host/databasedirectory> -m /var/db/mysql```
    Optional: ```pot set-env -p <mariadbjailname> -E DUMPSCHEDULE="<cronschedule>" [-E DUMPUSER=<backupuser>] [-E DUMPFILE=</insidejail/dumpfile.sql>]```
    Optional: ```pot copy-in -p <mariadbjailname> -s <host/configdirectory/>server.cnf -d /usr/local/etc/mysql/conf.d/server.cnf```

    Cron schedule is in the scheduling format of crontab, e.g. "*/5 * * * *".

    DUMPUSER defaults to ```root``` and DUMPFILE defaults to ```/var/db/mysql/full_mariadb_backup.sql``` if you set a DUMPSCHEDULE but do not specify one or both of these parameters.

# Usage

You can connect to the database server with a ```mariadb``` client according to the configuration you have copied in (or the default ```mariadb``` configuration). 


