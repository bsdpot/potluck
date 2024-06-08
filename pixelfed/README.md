---
author: "Bretton Vine"
title: Pixelfed
summary: Pixelfed is a single pot image for the federated images sharing application.
tags: ["pixelfed", "images", "pictures", "fediverse", "mastodon"]
---

# Overview

This flavour currently contains the ```pixelfed``` PHP application.

It is dependent on external Postgres instance, but uses a local socket-based redis instance.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Create your local jail from the image or the flavour files.
* Clone the local jail
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY="<32 byte Base64 key from consul keygen>" \
    -E APPNAME=<name of pixelfed instance> \
    -E DOMAIN=<domain name of pixelfed instance> \
    -E EMAIL=<email address for SSL certificate registration> \
    -E DBHOST=<database hostname or IP address> \
    -E DBPORT=<database port> \
    -E DBUSER=<database username> \
    -E DBPASS=<database password> \
    -E DBNAME=<database name, i.e. pixelfed> \
    -E MAILHOST=<smtp host> \
    -E MAILPORT=<smtp port> \
    -E MAILUSER=<smtp username> \
    -E MAILPASS=<smtp password> \
    -E MAILFROM=<smtp from address> \
    -E S3REGION=<s3 region or global> \
    -E S3USER=<s3 username> \
    -E S3PASS=<s3 password> \
    -E S3BUCKET=<s3 bucket> \
    -E S3URL=<s3 write point, include http or https> \
    -E S3ENDPOINT=<s3 endpoint, include http or https> \
    [ -E PVTCERT=<any value enables> ] \
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

The APPNAME parameter is the name of the pixelfed instance.

The DOMAIN parameter is the domain name of the pixelfed instance.

The EMAIL parameter is the email address associated with SSL certificate registration for the DOMAIN parameter. You must still set this even if PVTCERT option is enabled for self-signed certificate generation.

The parameters DBHOST, DBPORT, DBNAME, DBUSER, DBPASS relate to a postgresql instance for this pot jail. The user must be setup beforehand, see note below for database setup.

The parameters MAILHOST, MAILPORT, MAILUSER, MAILPASS, MAILFROM relate to an SMTP account for sending mail notices.

The parameters S3REGION, S3USER, S3PASS, S3BUCKET related to object storage configuration. This must be setup beforehand with applicable write permissions.

The parameter S3URL is the url to post to when writing to object storage. Include `http://` or `https://` as applicable.

The parameter S3ENDPOINT is the url for public read-only access to the bucket, such as served by `nginx-s3-nomad` or `nginx-s3-ssl-nomad` pot images. Include `https://`.

## Optional Parameters

The PVTCERT parameter will configure a self-signed certificate for use with `nginx`. Enable this if you have SSL certificates configured via a frontend such as `haproxy` which is reverse-proxying to this image. No `acme.sh` registration will take place.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

## Database setup

Before running this pot image, create a user for pixelfed with permissions to create databases on a running `postgresql` server.

```
sudo -u postgres psql -c "CREATE USER pixelfed with encrypted password 'pAsSwoRd' CREATEDB;"
```

# Usage

To be added.