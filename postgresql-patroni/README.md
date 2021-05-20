---
author: "Bretton Vine"
title: Patroni PostgreSQL
summary: This is a PostgreSQL server jail that supports redundancy via Patroni.
tags: ["postgresql", "patroni", "sql", "database"]
---

# Overview

This is a ```patroni postgresql``` jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

It requires 5 ```consul``` servers running and the IPs passed in as part of the ```pot env``` setup. The CONSULSERVERS parameter defines the consul server instances, and must be set as ```CONSULSERVERS='"10.0.0.2"'```` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4"'``` or ```CONSULSERVERS='"10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"'```

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

The jail exposes these parameters that can either be set via the environment or by setting the ```cook```parameters (the latter either via ```nomad```, see example below, or by editing the downloaded jails ```pot.conf``` file):

| Environment   | Content    | Unfilled column    |
| :----------   | :----------------: | :-----------|
| DATACENTER    | - datacentre name                                                               | ...    |
| NODENAME      | - unique name for node, each patroni-postgresql instance must have unique name  | ...    |
| MYIP          | - IP address of this node                                                       | ...    |
| SERVICETAG    | - service tag for node (master/replica/standby-leader)                          | ...    |
| CONSULSERVERS | - IPs of consul cluster in format ```'"x.x.x.x", "y.y.y.y", "z.z.z.z"'```       | ...    |
| ADMPASS       | - admin password                                                                | ...    |
| KEKPASS       | - postgresql super user password                                                | ...    |
| GOSSIPKEY     | - consul gossip encryption key in 32 byte base64 format                         | ...    |
