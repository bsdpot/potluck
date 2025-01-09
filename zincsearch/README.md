---
author: "Bretton Vine"
title: zincsearch
summary: zincsearch is an elasticsearch clone
tags: ["opensearch", "search", "elasticsearch"]
---

# Overview

This flavour contains a local `zincsearch` instance, a low footprint, non-java, `elasticsearch` clone.

It is currently expected that this jail will run on an internal IP with no remote access.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```. You can also connect to this host and ```service consul restart``` manually.

# Installation

* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in persistent storage
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
    -E ZINCUSER=<zincsearch admin user> \
    -E ZINCPASS=<zincsearch admin pass> \
    -E ZINCDATA=<path to store zincsearch files, default /mnt/zinc/data> \
    [ -E ZINCPORT=<zincsearch port, default 4080> ] \
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

The ZINCUSER and ZINCPASS parameters set the `zincsearch` admin user and password.

The ZINCDATA parameter is the directory to save `zincsearch` data files. Defaults to `/mnt/zinc/data`.

## Optional Parameters

The ZINCPORT parameter is the port to make `zincsearch` available on. Defaults to `4080`.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

WIP