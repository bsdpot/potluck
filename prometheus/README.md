---
author: "Bretton Vine"
title: Prometheus 
summary: Prometheus is a tool for capturing time series data, specifically system metrics.
tags: ["metrics", "time-series", "prometheus", "grafana"]
---

# Overview

This is a flavour containing the ```prometheus``` time series database.

It also contains ```node_exporter``` and ```grafana```.

The flavour includes a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Installation

* Create your local jail from the image or the flavour files. 
* Export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8200:8200```   
* Adjust to your environment:    
  ```sudo pot set-env -p prometheus-clone -E DATACENTER=<datacentername> -E NODENAME=<nodename> \
      -E IP=<IP address of this system> -E CONSULSERVERS='<correctly formatted list of quoted IP addresses>' \
      [-E GOSSIPKEY=<32 byte Base64 key from consul keygen>]```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

# Usage

To access prometheus open the following in a browser:
* http(s)://<prometheus-host>:9090
* http(s)://<prometheus-host>:9090/targets/

To access Grafana open the following in a browser:
* http(s)://<prometheus-host>:3000

If Grafana doesn't start, wait a few minutes and try again.

To access this node's own metrics, visit:
* http(s)://<prometheus-host>:9100/metrics

or run ```fetch -o - 'https://127.0.0.1:9100/metrics'```