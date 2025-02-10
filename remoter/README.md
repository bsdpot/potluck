---
author: "Bretton Vine"
title: Remoter
summary: Custom image for remote rsync of minio and database backups
tags: ["rsync", "development image", "custom image"]
---

# Overview

This is a development flavour containing ```rsync``` and ```ssh```, along with scripts to backup minio buckets, or database servers.

You probably want to adjust this flavour and rebuild your own pot image for your own systems.

# Installation

* Create a ZFS data set on the parent system beforehand, for example:
  ```zfs create -o mountpoint=/mnt/jaildata/remoter zroot/jaildata/remoter```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created:
  ```pot mount-in -p <jailname> -d /mnt/jaildata/remoter -m /mnt```
* Mandatory copy in SSH authorized_keys file for the SSHUSER:
  ```pot copy-in -p <jailname> -s /path/to/authorized_keys -d /root/authorized_keys_in```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
   -E DATACENTER=<datacentername> \
   -E NODENAME=<nodename> \
   -E IP=<IP address of this system> \
   -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
   -E GOSSIPKEY=<32 byte Base64 key from consul keygen> \
   -E SSHUSER=<username to create for ssh access> \
   -E BUCKET=<minio bucket name> \
   -E BUCKETHOST=<minio IP> \
   -E BUCKETUSER=<minio user> \
   -E BUCKETPASS=<minio password> \
   -E DATABASE=<db name> \
   -E DBUSER=<database username> \
   -E DBPASS=<database password> \
   -E DBHOST=<IP database host> \
   [ -E SSHPORT=<change ssh port, default "22022"> ] \
   [ -E DBPORT=<non-standard postgresql port> ] \
   [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```
* Start the jail

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The SSHUSER parameter is the name of the user to be created for ssh remote access. You must also copy in the user's `authorized_keys` file to `/root/authorized_keys_in`. User scripts are expecting this.

BUCKET is the name of the minio bucket used in scripts.

BUCKETHOST is the hostname or IP of a minio instance.

BUCKETUSER and BUCKETPASS are the credentials for accessing the minio bucket.

DATABASE is the name of a postgresql database to backup. 

DBUSER and DBPASS are the credentials for accessing the database.

DBHOST is the IP address of the postgresql host.

## Optional Parameters
SSHPORT is for setting a different SSH port to `22022`. 

DBPORT is for setting a non-standard postgresql port. Default is 

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

# Usage
TBA

# Persistent storage
To use persistent storage make sure to mount-in a pre-configured ZFS dataset to the applicable directory.
