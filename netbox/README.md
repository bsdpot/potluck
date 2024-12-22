---
author: "Bretton Vine"
title: Netbox
summary: Netbox is a pot image with multiple integrated applications for all in one install of netbox
tags: ["ipam", "netbox, "monitoring"]
---

# Overview

This flavour contains ```netbox``` with integrated ```postgresql```, ```redis```, ```gunicorn``` and ```nginx```. 

It is intended that the database and redis are integrated in this image, and independent of the rest of your pot infrastructure. Make sure to create a ZFS dataset and mount it in correctly to /mnt.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Create a ZFS data set on the parent system beforehand 
  ```
  zfs create -o mountpoint=/mnt/netdata zroot/netdata
  ```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```
  pot mount-in -p <jailname> -m /mnt -d /mnt/netdata
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
    -E DBPASSWORD=<database password> \
    -E MAILSERVER=<FQDN or IP of SMTP server> \
    -E MAILUSERNAME=<SMTP username> \
    -E ADMINEMAIL=<email address to receive notices> \
    -E FROMMAIL=<from address to use for SMTP account> \
    [ -E DUMPSCHEDULE="<cronschedule>" ] \
    [ -E DUMPPATH=<path for database backups> ] \
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

The DBPASSWORD parameter is a self-selected password for the local postgresql instance of netbox.

The MAILSERVER parameter is for the FQDN or IP address of your SMTP server.

The MAILUSERNAME and MAILPASSWORD parameters are for the credentials for the SMTP server.

The ADMINEMAIL parameter is the notification address to send mail to.

The FROMMAIL parameter is the sender address to use for the SMTP server.


## Optional Parameters

DUMPSCHEDULE is an optional parameter for a cronjob to dump the databases to file. Provide it in the scheduling format of crontab, e.g. "0 2 * * *". (include quotes)

DUMPPATH is an optional parameter for the path to store database backups. For example /mnt/pgbak.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

TBA, Netbox is a "source of truth" for your network with lots of configurable information, and an IP address management platform. 
