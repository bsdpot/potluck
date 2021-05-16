---
author: "Bretton Vine"
title: Vault 
summary: Vault is a tool for securely accessing secrets, such as API keys, passwords, or certificates.
tags: ["micro-services", "vault", "nomad", "secrets", "certificates"]
---

# Overview

This is a flavour containing the ```vault``` security storage platform.

You can e.g. store certificates, passwords etc to be used with the [nomad-server](https://potluck.honeyguide.net/blog/nomad-server/) ```pot``` flavour on this site.

The flavour expects a local ```consul``` agent instance to be available that it can connect to (see configuration below). You can e.g. use the [consul](https://potluck.honeyguide.net/blog/consul/) ```pot``` flavour on this site to run ```consul```.

# Installation

* Create your local jail from the image or the flavour files. 
* Export the ports after creating the jail:     
  ```pot export-ports -p <jailname> -e 8200:8200```   
* Adjust to your environment:    
  ```sudo pot set-env -p <jailname> -E DATACENTER=<datacentername> -E NODENAME=<nodename> -E CONSULSERVERS=<correctly-quoted-array-consul-IPs> -E IP=<IP address of this vault node>```

The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

# Usage

```vault``` is then running on port 8200 of your jail IP address.

The vault instance or cluster must first be initialised, and this stage of the image doesn't yet include HTTPS.

So you must include the parameter ```-address=http://<IP>:8200``` to any ```vault``` commands. For example:

```
$ vault operator init -address=http://10.0.0.10:8200

Unseal Key 1: key1
Unseal Key 2: key2
Unseal Key 3: key3
Unseal Key 4: key4
Unseal Key 5: key5

Initial Root Token: a.token

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 3 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

Unseal node 1:
```
$ vault operator unseal -address=http://10.0.0.10:8200 "key1"
$ vault operator unseal -address=http://10.0.0.10:8200 "key2"
$ vault operator unseal -address=http://10.0.0.10:8200 "key3"
```

and then on second node:
```
$ vault operator unseal -address=http://10.0.0.11:8200 "key1"
$ vault operator unseal -address=http://10.0.0.11:8200 "key2"
$ vault operator unseal -address=http://10.0.0.11:8200 "key3"
```

and on third node
```
$ vault operator unseal -address=http://10.0.0.12:8200 "key1"
$ vault operator unseal -address=http://10.0.0.12:8200 "key2"
$ vault operator unseal -address=http://10.0.0.12:8200 "key3"
```
