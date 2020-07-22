---
author: "Stephan Lichtenauer"
title: Nomad (Server)
summary: Nomad is a scalable orchestration tool to run jobs on many hosts.
tags: ["micro-services", "traefik", "nomad", "consul"]
---

# Overview

This is a flavour containing the ```nomad``` service orchestrator.

This flavour is configured as orchestration server. You need one or more ```nomad``` client instances that connect to this server and actually run the workload.

Since clients need to run jobs e.g. via ```pot```, you need to install the client directly on a host; therefore you will not find a ```nomad``` client flavour on potluck.

Together with [consul](https://potluck.honeyguide.net/blog/consul/) and the [traefik](https://potluck.honeyguide.net/blog/traefik-consul/) ```pot``` flavours on this site, you can easily set up a virtual datacenter.

Please note that a specific network configuration is suggested (see Installation-chapter).

# Installation

* Create your local jail from the image or the flavour files. 
* Export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 4646:4646 -e 4647:4647 -e 4648:4648```
* Adjust to your environment:    
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E IP=<IP address of this nomad instance>  -E CONSULSERVER=<IP or hostname of consulserver>```

# Usage

You can connect to the dashboard on port 4646 of your jail IP address.

To run a new job, connect to the jail via ```pot term <jailname>``` and run a ```nomad``` job description via ```nomad run -address=http://<jailip>:4646 <jobfile>``` or place the job via the dashboard.
