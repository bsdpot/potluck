---
author: "Bretton Vine"
title: Traumadrill
summary: Traumadrill is a single pot image with multiple benchmarking tools and stress generators for generating artificial system load.
tags: ["monitoring", "alerting", "benchmarking", "stress", "alertmanager", "testing"]
---

# Overview

This flavour currently contains ```stress-ng``` for generating artificial load and testing alert rules.

It is a work-in-progress for testing ```prometheus``` alert rules for system load within a pot environment.

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

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

Open a browser and navigate to ```http://traumadrill-ip/index.php``` and click the button to start a test.

Currently a fixed 5min test runs with the following parameters:

```
stress-ng --cpu 4 --vm 2 --hdd 1 --fork 8 --timeout 5m --metrics-brief --temp-path /tmp/stress-tmp/
```

There will be no output in the browser until 5min have passed, then brief metrics will be output.

To run another 5min test click the button again.

Watch for ```prometheus``` alerts, there should be a high CPU alert, or monitor ```grafana``` dashboards to see the load.

