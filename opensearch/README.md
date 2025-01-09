---
author: "Bretton Vine"
title: Opensearch
summary: Opensearch is an elasticsearch clone
tags: ["opensearch", "search", "elasticsearch"]
---

# Overview

This flavour contains a local `opensearch` instance, an `elasticsearch` clone.

It is expected that this jail will run on an internal IP with no remote access.

This version is compiled from ports with no plugins to avoid the TLS dependency. This is for internal/LAN use only.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Create your local jail from the image or the flavour files.
* Clone the local jail
* Set the following attributes 
  ```
  pot set-attribute -A fdescfs -V YES -p <jailname>
  pot set-attribute -A procfs -V YES -p <jailname>
  pot set-attribute -A enforce_statfs -V 1 -p <jailname>
  pot set-attribute -A mlock -V YES -p <jailname>
  ```
* Mount in persistent storage
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
    [ -E PORT=<opensearch port, default 9200> ] \
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

## Optional Parameters

The PORT parameter is the port to make `opensearch` available on. Defaults to `9200`.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

`opensearch` is a drop-in replacement for `elasticsearch`. 

The default username and password is `admin:admin`. Setting this on image start is still to come.

The data directory for `opensearch` is automatically set to `/mnt/opensearch`, which needs to be mounted-in persistent storage.

The image requires the following jail attributes get set manually:
```
set-attribute -A fdescfs -V YES
set-attribute -A procfs -V YES
set-attribute -A enforce_statfs -V 1
set-attribute -A mlock -V YES
```

WIP. Documentation to be added.
