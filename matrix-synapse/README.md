---
author: "Stephan Lichtenauer, Bretton Vine"
title: Matrix Synapse
summary: Matrix Synapse secure, decentralised, real-time communication server.
tags: ["matrix", "synapse", "im", "instant messaging", "rooms", "chat"]
---

# Overview

This is a Matrix-Synapse jail that can be started with ```pot```.

Important: this instance uses `sqlite` instead of `postgres` and may not be suitable for busy servers!

The jail exposes parameters that can either be set via the environment.

It also contains `node_exporter` and a local `consul` agent instance to be
available that it can connect to (see configuration below). You can e.g.
use the [consul](https://potluck.honeyguide.net/blog/consul/) `pot` flavour
on this site to run `consul`.

# Setup
You must run your matrix instance from a top level domain such as `example.com`, not `matrix.example.com`.

This is a quirk of using `.well-known/matrix/server` with the server's details.

## Installation

* Create a ZFS data set on the parent system beforehand
  ```
  zfs create -o mountpoint=/mnt/matrixdata zroot/matrixdata
  ```
* Create your local jail from the image or the flavour files.
* Clone the local jail
* Mount in the ZFS data set you created
  ```
  pot mount-in -p <jailname> -m /mnt -d /mnt/matrixdata
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
   -E DATACENTER=<datacenter name> \
   -E CONSULSERVERS="<comma-deliminated list of consul servers>" \
   -E GOSSIPKEY=<32 byte Base64 key from consul keygen>] \
   -E NODENAME=<name of node> \
   -E IP=<IP address> \
   -E DOMAIN=<domain name> \
   -E ALERTEMAIL=<alert email> \
   -E REGISTRATIONENABLE=<true|false> \
   -E MYSHAREDSECRET=<shared secret for registrations> \
   -E SMTPHOST=<mail host> \
   -E SMTPUSER=username \
   -E SMTPPASS=password \
   -E SMTPFROM=<email> \
   -E SSLEMAIL=<email address for certificate registration|none> \
   -E LDAPSERVER=<IP of LDAP server> \
   -E LDAPPASSWORD=<LDAP Manager password> \
   -E LDAPDOMAIN=<domain name for ldap> \
   -E CONTROLUSER=<true|false> \
   [ -E SMTPPORT=25 ] \
   [ -E NOSSL=<any value set disables SSL> ] \
   [ -E REMOTELOG=<IP of syslog-ng server> ]
  ```

The DATACENTER parameter is the name of the datacenter.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent.

The NODENAME parameter is the name of the node.

The IP parameter is the IP address of this image.

The DOMAIN parameter is the domain name to use for `matrix` configuration. It will be the same as the servername for the host.

ALERTEMAIL is an email address to use.

REGISTRATIONENABLE defaults to ```false``` but if set to ```true``` will allow registrations.

MYSHAREDSECRET is a shared secret key for registrations.

SMTPHOST is the mail server domain name or IP address.

SMTPPORT defaults to 25 but can be set to 465 or 587 manually.

SMTPUSER is the smtp username. SMTPPASS is the associated password.

SMTPFROM is the from email address for the authenticated SMTP user.

SSLEMAIL is an email address to use for SSL certificate registation. If NOSSL is also set, then set `-E SSLEMAIL=none` as it must have a value set at this time.

LDAPSERVER is the domain name or IP address of an LDAP server. Don't include a port!

LDAPPASSWORD is the password to access the LDAP server as Manager.

LDAPDOMAIN is the domain for the LDAP server which will be split into name.tld for the purposes of updating config.

CONTROLUSER enables a control user. Copy in a SSH pubkey to `/root/importauthkey` to have it imported to control user account.

NOSSL will disable SSL setup for any value set. You might want this for a reverse proxy setup with SSL handled in the proxy.

REMOTELOG is an optional parameter for a remote syslog service, such as via the `loki` or `beast-of-argh` images on potluck site.

## Usage

### First Account

You will need to setup an admin account via cli using ```register_new_matrix_user```.

For example:
```
register_new_matrix_user -u adminusername -k "Ex4mpl3sH4r3dk3y"
Password:
Confirm password:
Make admin [yes]:
Sending registration request...
Success!
```

The shared secret (-k) is defined in the homeserver.yaml configuration via the MYSHAREDSECRET parameter. The command asks for a password which should be unused as authentication should happen against LDAP.
