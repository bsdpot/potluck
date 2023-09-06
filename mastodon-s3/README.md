---
author: "Bretton Vine, Stephan Lichtenauer"
title: Mastodon S3
summary: This is an all-in-one Mastodon instance that can be deployed like a regular pot jail.
tags: ["mastodon", "social media"]
---

# Overview

This is an all-in-one ```mastodon``` installation that can be started with ```pot```.

The jail configures itself on the first start for your environment (see notes below).

This jail includes local ```postgresql``` and ```redis``` instances, and is dependent on S3 storage.

Deploying the image or flavour should be quite straight forward and not take more than a few minutes.

# Installation

* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in persistent storage to /mnt specifically
* Adjust to your environment:
  ```sudo pot set-env -p <clonejailname> \
    -E DATACENTER=<datacentername> \
    -E IP=<IP address of this nomad instance> \
    -E NODENAME=<an internal name for image> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY="<32 byte Base64 key from consul keygen>" \
    -E DOMAIN=<FQDN for host> \
    -E EMAIL=<email address for letsencrypt setup> \
    -E MAILHOST=<mailserver hostname or IP> \
    -E MAILPORT=<SMTP port> \
    -E MAILUSER=<SMTP username> \
    -E MAILPASS=<SMTP password> \
    -E MAILFROM=<SMTP from address> \
    -E BUCKETHOST=<hostname or IP of S3 storage> \
    -E BUCKETUSER=<S3 access id> \
    -E BUCKETPASS=<S3 password> \
    -E BUCKETALIAS=<web address for files> \
    -E BUCKETREGION=<S3 region> \
    [ -E REMOTELOG="<IP syslog-ng server>" ]```
* Start the pot: ```pot start <yourjailname>```. On the first run the jail will configure itself and start the services.

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The DOMAIN parameter is the domain name of the `jitsi-meet` instance.

The EMAIL parameter is the email address to use for letsencrypt registration. SSL certificates are mandatory, modern browsers won't open camera or microphone unless SSL enabled.

The MAILHOST parameter is the hostname or IP address of a mail server to us.

The MAILPORT parameter is the SMTP port to use of the mail server.

The MAILUSER and MAILPASS parameters are the mail user credentials.

The MAILFROM parameter is the from email address to use for notifications.

The BUCKETHOST paramter is the hostname of your S3 storage.

The BUCKETUSER parameter is the S3 access id of your storage.

The BUCKETPASS parameter is the S3 password of your storage.

The BUCKETALIAS parameter is the public hostname for the files storage.

The BUCKETREGION paramter is the S3 region.

## Optional Parameters

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

## Secret Key

A secret key is generated and stored in a file in persistent storage at `/mnt/mastodon/private/secret.key`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.

## OTP Key

An OTP key is generated and stored in a file in persistent storage at `/mnt/mastodon/private/opt.key`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.

## Vapid Keys

Vapid private/public keys are stored in a file in persistent storage at `/mnt/mastodon/private/vapid.keys`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.
