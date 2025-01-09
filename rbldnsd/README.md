---
author: "Bretton Vine"
title: Rbldnsd
summary: Rbldnsd is a pot image with a dns-based blocklist and automatic rules updating from github public rulesets.
tags: ["rbl", "mail", "blocklist", "security", "postfix"]
---

# Overview

This flavour currently contains ```rbldnsd``` for managing the DNS blocklist.

The ruleset is pulled from https://github.com/borestad/blocklist-abuseipdb

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
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
    -E DOMAIN=<your domain name> \
    -E SSLEMAIL="<email address for certificate rgistration>" \
    [ -E REMOTELOG=<IP address> ] \
    [ -E RULESET="ruleset" ]

  ```
* Start the jail

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The DOMAIN parameter is the domain name to use for this host. This will be utilised at bl.$DOMAIN and you must setup a DNS entry to match.

The SSLEMAIL parameter is the email address used to register the domain at `zerossl`. 

## Optional Parameters

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

The RULESET parameter is one of 1, 3, 7, 14, 30, 60, 90 or all, for the [ruleset sources](https://github.com/borestad/blocklist-abuseipdb). The default is 30 for 30d list.

# Usage

This early version just starts `rbldnsd` with the applicable ruleset, and can be added to `postfix` as a RBL.

A standard page is available at `https://bl.YOURDOMAIN` and RBL block messages with URIs are automatically directed to the default page.

# Testing rbldnsd

To test if working, take example IP 1.2.3.4, put in reverse notation, and append `bl.your.domain` and the IP to query:

```
host -t TXT 4.3.2.1.bl.your.domain ip.of.rbldnsd
```
