---
author: "Bretton Vine"
title: Vault 
summary: Vault is a tool for securely accessing secrets, such as API keys, passwords, or certificates.
tags: ["micro-services", "vault", "nomad", "secrets", "certificates"]
---

# Overview

This is a flavour containing the ```vault``` security storage platform.

You can e.g. store certificates, passwords etc to be used with the [nomad-server](https://potluck.honeyguide.net/blog/nomad-server/) ```pot``` flavour on this site.

The flavour expects a ```consul``` instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Installation

* Create your local jail from the image or the flavour files. 
* Export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8200:8200```   
* Adjust to your environment:    
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E CONSULSERVER=<consul-nodename> -E IP=<IP address of this vault node>```

# Usage

```vault``` is then running on port 8200 of your jail IP address.

