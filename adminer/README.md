---
author: "Deividas Gedgaudas"
title: Adminer
summary: A persistent (non-nomad) jail with Adminer (Full) & Adminer Editor (MySQL)
tags: ["adminer", "nginx", "php", "database"]
---

# Overview

> Adminer (formerly phpMinAdmin) is a full-featured database management tool written in PHP. Conversely to phpMyAdmin, it consist of a single file ready to deploy to the target server.
> Adminer is available for MySQL, PostgreSQL, SQLite and Oracle.

> Adminer Editor is both easy-to-use and user-friendly database data editing tool written in PHP. It is suitable for common users, as it provides high-level data manipulation

This flavour includes both **Adminer** (all languages, all database types) and **Adminer Editor** (all languages, only MySQL).  
It is a persistent (non-nomad) jail running `nginx`, `php-fpm` and `consul`, `node_exporter`.

# Configuration

Adminer *can* be configured using environment variables (`pot set-env -E VAR=value`) but it is not a requirement, due to Adminer not having any configuration out of the box.  
We have added the ability to use **adminer** without a login page:
* If you set `DBSERVER`, `DBUSER`, `DBPASS`, `DBNAME`, `DBDRIVER` environment variables the `index.php` is modified to push login credentials on load and then includes the main adminer source code.

To deploy `adminer-editor` instead of the full **Adminer** set environment variable `EDITOR` to `true`.

# Installation

* Create your local jail from the image or the flavour files.
* Clone the local jail
* Adjust to your environment:
  ```sh
  sudo pot set-env -p <jailname> \
   -E DATACENTER=<datacenter name> \
   -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
   -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
   -E NODENAME=<name of node> \
   -E IP=<IP address> \
   -E SERVERNAME=<hostname/IP> \
   [ -E REMOTELOG=<IP of syslog-ng server> ]
   [ -E EDITOR=<true/false> ]
   [ -E DBSERVER=<IP/hostname of the database> ]
   [ -E DBUSER=<database username> ]
   [ -E DBPASS=<database password> ]
   [ -E DBNAME=<database> ]
   [ -E DBDRIVER=<driver> ]
  ```
*Consul configuration:*  
The `DATACENTER` parameter is the name of the datacenter.  
The `CONSULSERVERS` parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!  
The `GOSSIPKEY` parameter is the gossip encryption key for consul agent.  
The `NODENAME` parameter is the name of the node.  
The `IP` parameter is the IP address of this image.

*Nginx configuration:*  
The `SERVERNAME` parameter is for nginx `servername` which sets your hostname

*Syslog configuration:*  
`REMOTELOG` is an optional parameter for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.  

*Adminer configuration (All of these are not required, can be left unset!):*  
`EDITOR` - Set this value to `true` to deploy **Adminer Editor**  
`DBSERVER` - IP or hostname of the database to connect to  
`DBUSER` & `DBPASS` - Database credentials to use to sign-in  
`DBNAME` - The databse to connect to (Can be left empty)  
`DBDRIVER` - Which PHP Driver to use:  
* `server` - MySQL
* `sqlite` - SQLite 3
* `sqlite2` - SQLite 2
* `pgsql` - PostgreSQL
* `oracle` - Oracle (beta)
