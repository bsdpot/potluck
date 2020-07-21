---
author: "Stephan Lichtenauer"
title: Traefik (Consul)
summary: traefik reverse proxy/load-balancer preconfigured for use with consul.
tags: ["reverse proxy", "traefik", "http", "load balancer", "web server", "consul"]
---

# Overview

This is a flavour containing the ```traefik``` reverse proxy and load balancer preconfigured for usage with ```consul```.

Please note that a specific network configuration is suggested (see Installation-chapter).

# Installation

* Create your local jail from the image or the flavour files. It is suggested that you create it with an alias network similar to the following command:    
```pot import -p traefik-consul-fbsd-amd64-12_1 -t 1.0 -N alias -i "em0|192.168.178.102“ -U https://potluck.honeyguide.net/traefik-consul```
* Adjust to your environment: ```sudo pot set-env -p <jailname> -E CONSULSERVER=<IP or hostname of consulserver>```

# Usage

```traefik``` in the jail is listening on port 8080.

You can connect to the dashboard on port 9002 of your jail IP address, with the example above that would be http://192.168.178.102:9002.

The services registered on your associated ```consul``` instance are available under their service name via the ```host:``` header (similar to e.g. Apache Virtual Hosts).    
To test this, you can use ```curl -H 'host: my-consul-servicename' 192.168.178.102:8080``` (again with the IP address from the example above).
