---
author: "Bretton Vine"
title: Mailhub-Potluck
summary: Mailhub-Potluck is a bespoke pot flavour with postfix-ldap, dovecot and related tools.
tags: ["email", "mail server", "postfix", "dovecot", "spamassassin"]
---

# Overview

This flavour is an application pot flavour with `postfix-ldap`, `dovecot`, `spamassassin` and related packages.

# Installation

* Create your local jail from the image or the flavour files.
* Setup persistent storage
* Clone the local jail
* Mount in persistent storage to /mnt
* Copy in local custom files
  ```
  sudo pot copy-in -p <jailname> -s /path/to/postfix_access -d /root/postfix_access
  sudo pot copy-in -p <jailname> -s /path/to/postfix_external_forwards -d /root/postfix_external_forwards
  sudo pot copy-in -p <jailname> -s /path/to/postfix_sender_transport -d /root/postfix_sender_transport
  sudo pot copy-in -p <jailname> -s /path/to/dkim_trusted_hosts -d /root/dkim_trusted_hosts
  sudo pot copy-in -p <jailname> -s /path/to/dkim_my_domains -d /root/dkim_my_domains
  sudo pot copy-in -p <jailname> -s /path/to/spamassassin_whitelist -d /root/spamassassin_whitelist
  ```
* Adjust to your environment:
  ```
  sudo pot set-env -p <jailname> \
    -E NODENAME=<nodename> \
    -E IP=<IP address of this system> \
    -E DATACENTER=<consul dc> \
    -E CONSULSERVERS=<IP address> \
    -E GOSSIPKEY="<gossipkey>" \
    -E LDAPSERVER=<IP address> \
    -E SEARCHBASE="<ldap config, see docs>" \
    -E POSTDATADIR=<directory of persistent storage> \
    -E POSTNETWORKS="<comma-deliminated list of IP/MASK>" \
    -E POSTDOMAINS="<comma-deliminated list of domains>" \
    -E MAILCERTDOMAIN=<FQDN of mail host> \
    -E SIGNDOMAINS="<comma-deliminated list of domains>"
    -E VHOSTDIR=<mount for mail folders> \
    -E POSTMASTERADDRESS=<postmaster email address> \
    -E MYSQLIP=<IP address mysql server> \
    -E MYSQLDB=<spamassassin db name> \
    -E MYSQLUSER=<username> -E MYSQLPASS=<password> \
    [-E REMOTELOG=<IP address of syslog-ng server>]
    [-E POSTSIZELIMIT=<size limit>] \
    [-E ROOTMAIL=<email address to send root's mail>]
  ```
* Start the jail

## Required Paramaters
The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The DATACENTER parameter is the `consul` datacenter.

The CONSULSERVERS parameter is a correctly formatted list of `consul` servers.

The GOSSIPKEY parameter is the gossip key for the consul datacenter.

The LDAPSERVER parameter is the IP address of the LDAP server to query.

The SEARCHBASE parameter is for LDAP usage in the format `"ou=People,dc=yourdomain,dc=tld"`

The POSTDATADIR parameter is the postfix data directory, such as `/var/db/postfix` or `/mnt/postfix` with a mount-in persistent storage.

The POSTNETWORKS parameter is a comma-deliminated list of host/mask addresses with zero restrictions and must include `"127.0.0.0/8, 10.0.0.0/8, host/mask, host/mask"`

> Do not set too broadly, do not list your gateway/firewall IP, else postfix will become an open relay.

The POSTDOMAINS parameter is a comma-deliminated list of domain names to accept mail for, such as `"domain.tld, other.com, newdomain.sh"`.

The MAILCERTDOMAIN parameter is the FQDN of the mail host requesting certificates, e.g. `mail.thishost.tld`

The SIGNDOMAINS parameter is a list of domains to sign and must match the domains in the copied in file `dkim_my_domains` .

The POSTMASTERADDRESS parameter is the postmaster address to use.

The VHOSTDIR parameter is the location of the user mail files. For persistent storage this would be something like `/mnt/dovecot`.

The MYSQLIP is the IP address or hostname of the mysql server to use with spamassassin.

The MYSQLDB is the name of the database to use with spamassassin. This must be pre-configured.

The MYSQLUSER and MYSQLPASS parameters are the user and password for accessing the mysql database.

## Optional Parameters
The REMOTELOG parameter is the IP address of a `syslog-ng` remote log service, such as via the `Beast of Argh` pot image.

The POSTSIZELIMIT parameter is to set the size of accepted mail. The default is `536870912`.

The ROOTMAIL parameter is an email address to use for redirecting root's mail.

## Optional files to copy in

### Postfix: Replace /usr/local/etc/postfix/access
Create the `postfix_access` file in the following format and copy-in to `/root/postfix_access`. Set hosts to reject here.
```
demo.sophimail.com    REJECT
```

### Postfix: Replace /usr/local/etc/postfix/external_forwards
Create the `postfix_external_forwards` file in the following format and copy-in to `/root/postfix_external_forwards`. Set forwards here.
```
address@domain.com           address@gmail.com
othercontact@newdomain.com   addressa@gmail.com, addressb@aol.com, addressc@anotherhost.com
```

### Postfix: Replace /usr/local/etc/postfix/sender_transport
Create a `postfix_sender_transport` file in the following format and copy-in to `/root/postfix_sender_transport`.
```
@demo.sophimail.com demo_com:
```

### Opendkim: Copy in Trustedhosts
Create the file `dkim_trusted_hosts`in the following format and copy-in to `/root/dkim_trusted_hosts`. Make sure to set `A.B.C.D/24` to your host/subnet and include additional host/subnet on additional lines.
```
127.0.0.0/8
10.0.0.0/8
A.B.C.D/24
```

### Opendkim: Copy in My DKIM Domains
Create the file `dkim_my_domains` in the following format and copy-in to `/root/dkim_my_domains`. Make sure only one domain per line and no empty lines.
```
mydomain.com
otherdomain.net
newdomain.rocks
```

Opendkim will be setup based on these entries.

### Spamassasssin: Copy in whitelist entries
Create the file `spamassassin_whitelist` in the following format and copy-in to `/root/spamassassin_whitelist`.
```
email@domain.com
email2@network.rocks
```

## MySQL setup for Spamassassin
You can create an empty database for spamassassin using the following, be sure to set the correct IP address:
```
mysql -u root -p
create database mail_spamassassin;
grant all privileges on mail_spamassassin.* to 'user_mail_spamassassin'@'10.0.0.1' identified by 'insecure-password';
flush privileges;
```

Alternatively import an existing database to a new mysql server for use:
```
mysql -u root -p mail_spamassassin < my-spamassassin-db.sql
mysql -u root -p
  use mail_spamassassin;
  grant all privileges on mail_spamassassin.* to 'user_mail_spamassassin'@'10.0.0.1' identified by 'insecure-password';
  flush privileges;
```

# Usage

Usage documentation pending.
