---
author: "Bretton Vine, Stephan Lichtenauer"
title: Mastodon S3
summary: This is a Mastodon instance that can be deployed like a regular pot jail.
tags: ["mastodon", "social media"]
---

# Overview

This is a ```mastodon``` installation that can be started with ```pot```.

The jail configures itself on the first start for your environment (see notes below).

Important: this jail is dependent on external ```postgresql``` and ```redis``` instances, along with S3 storage.

Deploying the image or flavour should be quite straight forward and not take more than a few minutes.

# Requirements

Do not startup this jail unless you have running ```postgresql``` and ```redis``` jails, such as Postgres-Single or Redis-Single on the potluck site.

# Installation

* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in persistent storage to /mnt specifically
* Adjust to your environment:
  ```
    sudo pot set-env -p <clonejailname> \
    -E DATACENTER=<datacentername> \
    -E IP=<IP address of this nomad instance> \
    -E NODENAME=<an internal name for image> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY="<32 byte Base64 key from consul keygen>" \
    -E DOMAIN=<FQDN for host> \
    -E EMAIL=<email address for letsencrypt setup> \
    -E MAILHOST=<mailserver hostname or IP> \
    -E MAILUSER=<SMTP username> \
    -E MAILPASS=<SMTP password> \
    -E MAILFROM=<SMTP from address> \
    -E DBHOST=<host of postgres jail> \
    -E DBUSER=<username> \
    -E DBPASS=<password> \
    -E DBNAME=<database name> \
    -E REDISHOST=<IP of redis instance> \
    -E BUCKETHOST=<hostname or IP of S3 storage> \
    -E BUCKETUSER=<S3 access id> \
    -E BUCKETPASS=<S3 password> \
    -E BUCKETALIAS=<web address for files> \
    -E BUCKETREGION=<S3 region> \
    [ -E MAILPORT=<SMTP port> ] \
    [ -E DBPORT=<database port> ] \
    [ -E REDISPORT=<redis port> ] \
    [ -E REMOTELOG="<IP syslog-ng server>" ]
  ```
* Start the pot: ```pot start <yourjailname>```. On the first run the jail will configure itself and start the services.

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The DOMAIN parameter is the domain name of the `mastodon-s3` instance.

The EMAIL parameter is the email address to use for letsencrypt registration. SSL certificates are mandatory, modern browsers won't open camera or microphone unless SSL enabled.

The MAILHOST parameter is the hostname or IP address of a mail server to us.

The MAILUSER and MAILPASS parameters are the mail user credentials.

The MAILFROM parameter is the from email address to use for notifications.

The DBHOST parameter is the IP address or hostname of the external `postgresql` instance, such as the `postgresql-single` potluck instance.

The DBUSER parameter is the username to use for accessing the external `postgresql` instance. Usually this would be `mastodon`. 

The DBPASS parameter is the password for the user on the external `postgresql` instance.

The DBNAME parameter is the database name on the external `postgresql` instance. Normally this would be `mastodon_production`.

The REDISHOST parameter is the IP address of a LAN-based `redis` host, such as the `redis-single` potluck instance.

The BUCKETHOST paramter is the hostname of your S3 storage.

The BUCKETUSER parameter is the S3 access id of your storage.

The BUCKETPASS parameter is the S3 password of your storage.

The BUCKETALIAS parameter is the public hostname for the files storage.

The BUCKETREGION parameter is the S3 region.

## Optional Parameters

The MAILPORT parameter is the SMTP port to use of the mail server. It defaults to port `25` if not set.

The DBPORT parameter is the port to use for `postgresql`. It defaults to port `5432` if not set.

The REDISPORT parameter is the port to use for `redis`. It defaults to port `6379` if not set.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

## Secret Key

A secret key is generated and stored in a file in persistent storage at `/mnt/mastodon/private/secret.key`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.

## OTP Key

An OTP key is generated and stored in a file in persistent storage at `/mnt/mastodon/private/otp.key`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.

## Vapid Keys

Vapid private/public keys are stored in a file in persistent storage at `/mnt/mastodon/private/vapid.keys`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.
