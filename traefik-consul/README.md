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
* Adjust to your environment:
  ```sudo pot set-env -p <jailname> -E CONSULSERVER=<IP or hostname of consulserver> [ -E REMOTELOG=<IP of remote syslog server> ]```
* Optional: Mount your traefik log storage directory into the jail:
  ```sudo pot mount-in -p <jailname> -m /var/log/traefik -d <logdirectory_on_host>```
* Start jail with ```pot start```

The CONSULSERVER parameter is the IP address of a consul server to get setup from.

The optional REMOTELOG parameter is the IP address of a remote syslog server.

# Usage

```traefik``` in the jail is listening on port 8080 (HTTP) and 8443 (HTTPS with self signed certificate).

You can connect to the dashboard on port 9002 of your jail IP address.

The services registered on your associated ```consul``` instance are available under their service name via the ```host:``` header (similar to e.g. Apache Virtual Hosts).
To test this, you can use ```curl -H 'host: my-consul-servicename' <jailip>:8080```.
