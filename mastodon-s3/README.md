---
author: "Bretton Vine, Stephan Lichtenauer"
title: Mastodon S3
summary: This is a Mastodon instance that can be deployed like a regular pot jail.
tags: ["mastodon", "social media"]
---

# Overview

This is a ```mastodon``` installation that can be started with ```pot```.

The jail configures itself on the first start for your environment (see notes below).

Important: this jail is dependent on external ```postgresql``` and ```redis``` instances, along with S3 storage.

Your S3 storage also needs a frontend such as ```nginx-s3-nomad``` configured beforehand.

Deploying the image or flavour should be quite straight forward, however it will take some time to become functional. This is not a fast image to boot!

The `mastodon` image is a non-layered pot jail, and can take a short while to boot assets compiling.

Once started the public-facing website can take several minutes of showing a blank or error page before showing the expected Mastodon default page.

# Requirements

Do not startup this jail unless you have running ```postgresql``` and ```redis``` jails, such as the Postgres-Single or Redis-Single pot jails on the potluck site.

You also need a S3 bucket setup, with anonymous download enabled, and a user/pass setup for the mastodon user.

Then setup ```nginx-s3-nomad``` or similar with access to that bucket. 

You will need an external HTTPS provider, such as ```acme.sh``` and  ```haproxy``` on your firewall device, with rule for the nomad pot image.

However the mastodon pot jail will register a SSL certificate directly.

# Installation

* Create your local jail from the image or the flavour files.
* Create a ZFS dataset for certificates and keys
* Clone the local jail
* Mount in persistent storage for certificates and keys to /mnt specifically
* Adjust to your environment:
  ```
	sudo pot set-env -p <clonejailname> \
	-E DATACENTER=<datacentername> \
	-E IP=<IP address of this nomad instance> \
	-E NODENAME=<an internal name for image> \
	-E CONSULSERVERS="<comma-deliminated list of consul servers>" \
	-E GOSSIPKEY="<32 byte Base64 key from consul keygen>" \
	-E DOMAIN=<FQDN for host> \
	-E EMAIL=<email address for letsencrypt setup> \
	-E MAILHOST=<mailserver hostname or IP> \
	-E MAILUSER=<SMTP username> \
	-E MAILPASS=<SMTP password> \
	-E MAILFROM=<SMTP from address> \
	-E DBHOST=<host of postgres jail> \
	-E DBUSER=<username> \
	-E DBPASS=<password> \
	-E DBNAME=<database name> \
	-E REDISHOST=<IP of redis instance> \
	-E BUCKETNAME=<bucket name on S3 host> \
	-E S3HOSTNAME=<S3 hostname> \
	-E S3PORT=<port for S3, or proxy, 80, 443, 8080> \
	-E BUCKETUSER=<S3 access id> \
	-E BUCKETPASS=<S3 password> \
	-E BUCKETALIAS=<web address for files, or alt domain name> \
	-E BUCKETREGION=<S3 region> \
	[ -E S3UPNOSSL=<any value enables http upload to S3 instead of https, must enable if S3PORT set to 80 or 8080> ] \
	[ -E MAILPORT=<SMTP port> ] \
	[ -E DBPORT=<database port> ] \
	[ -E REDISPORT=<redis port> ] \
	[ -E REMOTELOG="<IP syslog-ng server>" ] \
	[ -E MYSECRETKEY="<rails secret key>" ] \
	[ -E MYOTPSECRET="<rails secret key for otp>" ] \
	[ -E MYVAPIDPRIVATEKEY="<vapid private key>" ] \
	[ -E MYVAPIDPUBLICKEY="<vapid public key>" ] \
	[ -E MY_ACTIVE_PRIMARY_KEY="<key>" ] \
        [ -E MY_ACTIVE_DETERMINISTIC_KEY="<key>" ] \
        [ -E MY_ACTIVE_KEY_DERIVATION_SALT="<key>" ] \
	[ -E PVTCERT=<any value enables> ] \
	[ -E ELASTICENABLE=<any value enables> ] \
	[ -E ELASTICHOST=<IP of elasticsearch or zincsearch instance> ] \
	[ -E ELASTICPORT=<port of ES instance, default 9200> ] \
	[ -E ELASTICUSER=<username for ES instance > ] \
	[ -E ELASTICPASS=<password for ES instance > ] \
	[ -E DEEPLKEY=<API key> ] \
	[ -E DEEPLPLAN=<API plan or free> ] \
	[ -E OWNERNAME=<admin username> ] \
	[ -E OWNEREMAIL=<admin email address> ]
  ```
* Start the pot: ```pot start <yourjailname>```. On the first run the jail will configure itself and start the services.

## Required Paramaters
The DATACENTER parameter defines a common datacenter.

The NODENAME parameter defines the name of this node.

The IP parameter is the IP address which will be used to access services.

The CONSULSERVERS parameter is a comma-deliminated list of IP addresses for the consul server or cluster. Do not include spaces!

e.g. ```CONSULSERVERS="10.0.0.2"``` or ```CONSULSERVERS="10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5,10.0.0.6"```

The GOSSIPKEY parameter is the gossip encryption key for consul agent. We're using a default key if you do not set the parameter, do not use the default key for production encryption, instead provide your own.

The DOMAIN parameter is the domain name of the `mastodon-s3` instance.

The EMAIL parameter is the email address to use for letsencrypt registration. SSL certificates are mandatory, modern browsers won't open camera or microphone unless SSL enabled.

The MAILHOST parameter is the hostname or IP address of a mail server to us. Legacy SSL is not supported, older mail hosts are not suitable.

The MAILUSER and MAILPASS parameters are the mail user credentials.

The MAILFROM parameter is the from email address to use for notifications.

The DBHOST parameter is the IP address or hostname of the external `postgresql` instance, such as the `postgresql-single` potluck instance.

The DBUSER parameter is the username to use for accessing the external `postgresql` instance. Usually this would be `mastodon`. 

The DBPASS parameter is the password for the user on the external `postgresql` instance.

The DBNAME parameter is the database name on the external `postgresql` instance. Normally this would be `mastodon_production`.

The REDISHOST parameter is the IP address of a LAN-based `redis` host, such as the `redis-single` potluck instance.

The BUCKETNAME parameter is the name of your bucket in S3 storage.

The S3HOSTNAME parameter is the hostname or IP of your S3 storage.

The BUCKETUSER parameter is the S3 access-id for your storage.

The BUCKETPASS parameter is the S3 password for your storage.

The BUCKETALIAS parameter is an external hostname for the S3 storage, such as reverse proxy front-end.

The BUCKETREGION parameter is the S3 region.

## Optional Parameters

The S3PORT parameter defaults to port 443, but if set, can be configured for port 80 for haproxy-minio, or port 8080 for haproxy-minio varnish.

The S3UPNOSSL parameter will set `http://` uploads to S3 object storage, such as a local minio where self-signed certificate fails. Otherwise defaults to `https://`. You must set this if the S3PORT parameter is set to port 80 or 8080.

The MAILPORT parameter is the SMTP port to use of the mail server. It defaults to port `25` if not set.

The DBPORT parameter is the port to use for `postgresql`. It defaults to port `5432` if not set.

The REDISPORT parameter is the port to use for `redis`. It defaults to port `6379` if not set.

The REMOTELOG parameter is the IP address of a destination ```syslog-ng``` server, such as with the ```loki``` flavour, or ```beast-of-argh``` flavour.

The MYSECRETKEY parameter is an optional passed-in secret key for the `.env.production` value `SECRET_KEY_BASE`.

The MYOTPSECRET parameter is an optional passed-in OTP key for the `.env.production` value `OTP_SECRET`.

The MYVAPIDPRIVATEKEY parameter is an optional passed-in secret key for the `.env.production` value `VAPID_PRIVATE_KEY`.

The MYVAPIDPUBLICKEY parameter is an optional passed-in secret key for the `.env.production` value `VAPID_PUBLIC_KEY`.

The optional parameters MY_ACTIVE_PRIMARY_KEY, MY_ACTIVE_DETERMINISTIC_KEY, MY_ACTIVE_KEY_DERIVATION_SALT relate to new Ruby Active Record Encryption keys, as from 4.3.1 onwards. These are automatically generated first time, but need to be passed in for system migrations to a new host using existing values from `.env.production`.

The PVTCERT parameter is an optional value which generates self-signed certificates instead of using `acme.sh`. This is used in testing, or if there is a frontend that handles SSL certificates, such as `haproxy`. You must still pass in an EMAIL parameter even though it's not used.

The ELASTICENABLE parameter is enabled if set to any value, and requires the following additional parameters too.

The ELASTICHOST parameter is the IP address or hostname of an `elasticsearch` or `zincsearch` instance. 

The ELASTICPORT parameter is the port of the `elasticsearch` or `zincsearch` instance.

The ELASTICUSER and ELASTICPASS parameters are the credentials for the `elasticsearch` or `zincsearch` instance.

The DEEPLKEY parameter is the API key for the [DeepL translation service](https://www.deepl.com/translator). In unset a default, invalid key will be set.

The DEEPLPLAN is the type of API plan. If using the free plan set this value to 'free'. If unset it will default to 'free'.

The OWNERNAME is the username of the Owner account on a fresh instance. Setting this simply hard-codes it in the script. The script must still be run manually.

The OWNEREMAIL is the email address of the Owner account. Setting this simply hard-codes it in the script. The script must still be run manually.

# Usage

## Secret Key

A secret key is passed in, or generated, and stored in a file in persistent storage at `/mnt/mastodon/private/secret.key`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.

## OTP Key

An OTP key is passed-in, or generated, and stored in a file in persistent storage at `/mnt/mastodon/private/otp.key`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.

## Vapid Keys

Vapid private/public keys are passed in, or generated, and stored in a file in persistent storage at `/mnt/mastodon/private/vapid.keys`

On reboot or an upgraded pot image, this file will be read to configure the `mastodon` settings.

## Upgrading Mastodon

Stop the existing mastodon instance, and re-run provisioning with newer pot image.

## Custom fork of Mastodon

This uses a custom fork of Mastodon with a 5000 character limit, from https://github.com/woganmay/mastodon in the v4.2.1-patch tag.

## Maintenance Scripts

There are several useful scripts in `/root/bin/` which can be used to create an admin user, or reset 2FA, or clear media, or produce diagnostic output.

The `/root/bin/create-admin-user.sh` has the admin user and email set by the passed in parameters OWNERNAME and OWNEREMAIL.

A password will be created and user credentials will be saved in `/mnt/mastodon/private/mastodon.owner.credentials`

### Full Text Search

To enable full text search, pass in the relevant elasticsearch parameters, and once live, run
```
/root/bin/setup-es-index.sh
```

You can also rebuild an existing elasticsearch configuration with
```
/root/bin/rebuild-es-index.sh
```

