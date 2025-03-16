---
author: "Bretton Vine"
title: Onlyoffice-Documentserver
summary: Onlyoffice-Documentserver is a single pot image with documentserver for use by Nextcloud
tags: ["docs", "nextcloud", "office"]
---

# Overview

This is a development jail. Do not use in production yet.

Be aware, this is a large jail image.

This flavour currently contains ```onlyoffice-documentserver``` for live editing documents, paired with a separate Nextcloud instance.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Create a ZFS dataset beforehand, for example:
```
zfs create -o mountpoint=/mnt/documentserver zroot/data/documentserver
```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in persistent storage to /mnt specifically
```
pot mount-in -p <jailname> -m /mnt -d /mnt/documentserver
```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
    -E DOMAIN=<FQDN for host> \
    -E EMAIL=<email address for letsencrypt setup> \
    -E DBHOST=<database hostname or IP address> \
    -E DBUSER=<database username> \
    -E DBPASS=<database password> \
    -E DBNAME=<database name, i.e. onlyoffice> \
    [ -E PVTCERT=<any value enables self-signed certificates instead of using acme.sh> ] \
    [ -E DBPORT=<database port> ] \
    [ -E SECRETSTRING=<secret string> ] \
    [ -E RABBITONLYOFFICEPASS=<password for rabbitmq onlyoffice user> ] \
    [ -E REMOTELOG=<IP address> ]
  ```
* Start the jail

## Required Paramaters

The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The DOMAIN parameter is the domain name of the onlyoffice-documentserver instance.

The EMAIL parameter is the email address to use for letsencrypt registration. This must still be passed in if using the self-signed certificate parameter PVTCERT.

The parameters DBHOST, DBNAME, DBUSER, DBPASS relate to a postgresql instance. The database and user permissions must be setup in advance of running this jail. Refer note below for database setup.

## Optional Parameters

The PVTCERT parameter is an optional value which generates self-signed certificates instead of using acme.sh. This is used in testing, or if there is a frontend that handles SSL certificates, such as haproxy. You must still pass in an EMAIL parameter even though it's not used.

The DBPORT parameter defaults to 5432, yet can be set to another port by setting this parameter.

The SECRETSTRING parameter will be automatically created if not passed in. This password will be used by the Nextcloud Onlyoffice connector.

The RABBITONLYOFFICEPASS parameter will be automatically created if not passed in.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

## Database setup

Before running this pot image, create a database and user with permissions on a separate postgresql jail as follows:
```
sudo -u postgres psql -c "CREATE DATABASE onlyoffice;"
sudo -u postgres psql -c "CREATE USER onlyoffice WITH password 'REPLACE-PASSWORD';"
sudo -u postgres psql -c "GRANT ALL privileges ON DATABASE onlyoffice TO onlyoffice;"
sudo -u postgres psql -c "ALTER DATABASE onlyoffice OWNER to onlyoffice;"
```

Then pass in the relevant values to jail for DBHOST, DBNAME, DBUSER, DBPASS, and optionally DBPORT.

# Usage

The shared secret to use in Nextcloud connector will be in `/mnt/private/documentserver.txt`.

See https://api.onlyoffice.com/editors/nextcloud for more details on configuring Nextcloud.