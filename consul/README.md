---
author: "Stephan Lichtenauer, Bretton Vine"
title: Consul
summary: Consul is a service discovery platform for micro-services.
tags: ["micro-services", "traefik", "nomad", "consul"]
---

# Overview

This is a flavour containing the ```consul``` service discovery platform.

Together with the [nomad-server](https://potluck.honeyguide.net/blog/nomad-server/) and the [traefik](https://potluck.honeyguide.net/blog/traefik-consul/) ```pot``` flavours on this site, you can easily set up a virtual datacenter.

# Installation

* Create your local jail from the image or the flavour files.
* Export the ports after creating the jail:
  ```pot export-ports -p <jailname> -e 8500:8500```
  Note: If you want to use the ```consul``` DNS service, you either need to expose the DNS UDP port like for the [Jitsi Meet Nomad potluck image](https://potluck.honeyguide.net/blog/jitsi-meet-nomad/) or you need to clone the jail and assign a host IP address (like for the [Nomad Server image](https://potluck.honeyguide.net/blog/nomad-server/)).
* Adjust to your environment:
```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<consul-nodename> -E IP=<IP address of this consul node> [-E BOOTSTRAP=<1|3|5>] [-E GOSSIPKEY="<32 byte Base64 consul keygen key>"] [-E REMOTELOG=<ip address remote syslog server> ]```

The BOOTSTRAP parameter defines the expected number of cluster nodes, it defaults to 1 (no cluster) if it is not set.

For 3 and 5 node clusters the other peers must be passed in via the PEERS variable in the following format.

```-E IP=10.0.0.1 -E PEERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5"'```

The GOSSIPKEY parameter is to enable custom gossip encryption and defaults to a standard key. Do not use the default key for production encryption, instead provide your own with ```consul keygen```.

The REMOTELOG parameter is the IP address of a remote syslog server to send logs to.

# Usage

You can connect to the dashboard on port 8500 of your jail IP address.
