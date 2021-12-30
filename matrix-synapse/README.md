---
author: "Stephan Lichtenauer, Bretton Vine"
title: Matrix Synapse
summary: Matrix Synapse secure, decentralised, real-time communication server.
tags: ["matrix", "synapse", "im", "instant messaging"]
---

# Overview

This is a Matrix-Synapse jail that can be started with ```pot```.

This instance uses `sqlite` instead of `postgres` and may not be suitable for busy servers.

The jail exposes parameters that can either be set via the environment or by setting the ```cook```parameters (the 
latter either via ```nomad```, see example below, or by editing the downloaded jails ```pot.conf``` file):

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

# Setup

## Installation

* Create a ZFS data set on the parent system beforehand    
  ```zfs create -o mountpoint=/mnt/matrixdata zroot/matrixdata```
* Create your local jail from the image or the flavour files. 
* Clone the local jail
* Mount in the ZFS data set you created    
  ```pot mount-in -p <jailname> -m /mnt -d /mnt/matrixdata```
* Adjust to your environment:    
  ```
  sudo pot set-env -p <jailname> \
   -E DOMAIN=<domain name> -E IP=<IP address> \
   -E ALERTEMAIL=<alert email> \
   -E REGISTRATIONENABLE=<true|false> \
   -E MYSHAREDSECRET=<shared secret for registrations> \
   -E SMTPHOST=<mail host> [-E SMTPPORT=25 ] \
   -E SMTPUSER=username -E SMTPPASS=password -E SMTPFROM=<email> \
   -E LDAPSERVER=<IP> -E LDAPPASSWORD=<password> -E LDAPDOMAIN=<domain for ldap> \
   -E NOSSL=<true|false> -E CONTROLUSER=<true|false>
  ```

The DOMAIN parameter is the domain name to use for `matrix` configuration. It will be the same as the servername for the host.

The IP parameter is the IP address of this image.

ALERTEMAIL is an email address to use.

REGISTRATIONENABLE defaults to ```false``` but if set to ```true``` will allow registrations.

MYSHAREDSECRET is a shared secret key for registrations.

SMTPHOST is the mail server domain name or IP address. 

SMTPPORT defaults to 25 but can be set to 465 or 587 manually.

SMTPUSER is the smtp username. SMTPPASS is the associated password.

SMTPFROM is the from email address for the authenticated SMTP user.

LDAPSERVER is the domain name or IP address of an LDAP server. Don't include a port!

LDAPPASSWORD is the password to access the LDAP server.

LDAPDOMAIN is the domain for the LDAP server which will be split into name.tld for the purposes of updating config.

## Usage

To be added.