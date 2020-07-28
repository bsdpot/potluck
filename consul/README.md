---
author: "Stephan Lichtenauer"
title: Consul
summary: Consul is a service discovery platform for micro-services.
tags: ["micro-services", "traefik", "nomad", "consul"]
---

# Overview

This is a flavour containing the ```consul``` service discovery platform.

Together with the [nomad-server](https://potluck.honeyguide.net/blog/nomad-server/] and the [traefik](https://potluck.honeyguide.net/blog/traefik-consul/] ```pot``` flavours on this site, you can easily set up a virtual datacenter.

# Installation

* Create your local jail from the image or the flavour files. 
* Export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8500:8500```   
  Note: If you want to use the ```consul``` DNS service, you either need to expose the DNS UDP port like for the [Jitsi Meet Nomad potluck image](https://potluck.honeyguide.net/blog/jitsi-meet-nomad/) or you need to clone the jail and assign a host IP address (like for the [Nomad Server image](https://potluck.honeyguide.net/blog/nomad-server/)).
* Adjust to your environment:    
```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<consul-nodename> -E IP=<IP address of this consul node>```

# Usage

You can connect to the dashboard on port 8500 of your jail IP address.
