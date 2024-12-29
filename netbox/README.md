---
author: "Bretton Vine"
title: Netbox
summary: Netbox is a pot image with multiple integrated applications for all in one install of netbox
tags: ["ipam", "netbox", "monitoring"]
---

# Overview

This flavour contains ```netbox```, a solution for modeling and documenting modern networks, including rack management, IPAM, and more.

It serves as a source of truth for your network.

This image is dependent on external postgresql, a dedicated redis pot image, and consul pot image.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Preparation

You must prepare a postgresql server beforehand by creating the user and database with correct permissions:
```
sudo -u postgres psql -c "CREATE USER netbox with encrypted password 'YOUR-PASSWORD' CREATEDB;"
sudo -u postgres psql -c "CREATE DATABASE netbox TEMPLATE template0 ENCODING 'UTF8';"
sudo -u postgres psql -c "ALTER DATABASE netbox OWNER TO netbox;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON SCHEMA public TO netbox;"
```

You will also need a redis pot jail dedicated to netbox, as two databases are used, which may cause problems in a redis setup shared with other applications.

# Installation

* Create a ZFS data set on the parent system beforehand 
  ```
  zfs create -o mountpoint=/mnt/netdata zroot/netbox
  ```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```
  pot mount-in -p <jailname> -m /mnt -d /mnt/netbox
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
    -E DOMAIN=<FQDN for Allowed_Hosts parameter> \
    -E DBHOST=<IP of postgresql instance> \
    -E DBNAME=<database name> \
    -E DBUSER=<database username> \
    -E DBPASSWORD=<database password> \
    -E REDISHOST=<IP of dedicated redis instance> \
    -E MAILSERVER=<FQDN or IP of SMTP server> \
    -E MAILUSERNAME=<SMTP username> \
    -E MAILPASSWORD=<SMTP password> \
    -E FROMMAIL=<from address to use for SMTP account> \
    -E ADMINNAME=<name of netbox administrator account> \
    -E ADMINEMAIL=<email address to receive notices> \
    -E ADMINPASSWORD=<password for netbox superuser> \
    [ -E DBPORT=<postgresql port> ] \
    [ -E REDISPORT=<redis port> ] \
    [ -E MAILPORT=<SMTP port> ] \
    [ -E PVTCERT=<any value enables self-signed SSL certificate> ] \
    [ -E CERTEMAIL=<email address for acme.sh certificate registration> ] \
    [ -E REMOTELOG=<IP address> ]
  ```
* Start the jail

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent and must be configured separately with consul host.

The DOMAIN parameter is the FQDN of the frontend, as configured in host haproxy setup. This will go into the ALLOWED_HOSTS parameter for netbox.

The DBHOST parameter is the IP address or hostname of the postgresql server.

The DBNAME parameter is the database name on the postgresql server.

The DBUSER and DBPASSWORD parameters are the credentials to access the postgresql server.

The REDISHOST parameter is the IP address of a dedicated redis pot jail. Two databases are used, where it's not suitable to use a redis instance shared with other applications.

The MAILSERVER parameter is for the FQDN or IP address of your SMTP server.

The MAILUSERNAME and MAILPASSWORD parameters are the credentials for the SMTP server.

The FROMMAIL parameter is the sender address to use for the SMTP server.

The ADMINNAME parameter is the name of the netbox superuser account. It could be a user, or Administrator.

The ADMINEMAIL parameter is the email address of the superuser account, also used for system notifications.

The ADMINPASSWORD parameter is the password for the superuser account.

## Optional Parameters

DBPORT is an optional parameter that can be set if the default database port differs from postgresql default of 5432.

MAILPORT is an optional parameter that can be set if the default SMTP port differs from port 25.

REDISPORT is an optional parameter that can be set if the default redis port differs from port 6379.

PVTCERT is an optional parameter to make use of self-signed SSL certificates instead of acme.sh for registation. Use this if your frontend proxy does SSL already.

CERTEMAIL is an optional parameter to set a custom email address for acme.sh certificate registrations. If not set, ADMINEMAIL is used instead.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

TBA, Netbox is a "source of truth" for your network, with lots of configurable information, and IPAM for managing IP address allocations.

Login with your configured superuser credentials and provision a site, add a rack, add manufacturers, device types, then add devices in the rack.

Make sure you have pictures of the front and back of every server and network device to upload for the device entries.

Add additional users to assist with the task of documenting your infrastructure. 
