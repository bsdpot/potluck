---
author: "Stephan Lichtenauer, Bretton Vine"
title: Traefik (Consul)
summary: Traefik reverse proxy/load-balancer preconfigured for use with consul.
tags: ["reverse proxy", "traefik", "http", "load balancer", "web server", "consul"]
---

# Overview

This is a flavour containing the ```traefik``` reverse proxy and load balancer preconfigured for usage with ```consul``` (e.g. [consul pot image on potluck](https://potluck.honeyguide.net/blog/consul/).

# Installation

* Create your local jail from the image or the flavour files.
* Export the ports after creating the jail:
  ```pot export-ports -p <jailname> -e 8080:8080 -e 9002:9002```
* Optional: Mount your traefik log storage directory into the jail:
  ```sudo pot mount-in -p <jailname> -m /var/log/traefik -d <logdirectory_on_host>```
* Copy in local custom files.
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E DATACENTER=<datacentername> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E CONSULSERVERS="<comma-deliminated list of consul IP addresses>" \
    -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
    [ -E REMOTELOG=<IP address> ]
  ```
* Start jail with ```pot start <jailname>```

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter defines the consul server instances, and must be set as a comma-deliminated list. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

## Optional Parameters

The DISABLEUI parameter will disable the web UI if set to any value. The UI is enabled by default.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage

```traefik``` in the jail is listening on port 8080 (HTTP) and 8443 (HTTPS with self signed certificate).

You can connect to the dashboard on port 9002 of your jail IP address.

The services registered on your associated ```consul``` instance are available under their service name via the ```host:``` header (similar to e.g. Apache Virtual Hosts).
To test this, you can use ```curl -H 'host: my-consul-servicename' <jailip>:8080```.

# Consul DNS

Consul DNS works in the format `servicename.service.consul` or `nodename.node.consul`.

Consul DNS is integrated with local unbound in this image. You can query consul DNS like any normal DNS query directly to localhost.

To get a list of services listed in `consul` you can do the following:

```
curl -s "http://127.0.0.1:8500/v1/catalog/services" | jq
```

You can query the IP address of a service with

```
drill servicename.service.consul
```