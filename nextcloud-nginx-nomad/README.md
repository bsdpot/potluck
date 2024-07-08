---
author: "Bretton Vine"
title: Nextcloud on NGINX (Nomad)
summary: This is a Nextcloud jail preconfigured with NGINX that can be deployed via nomad.
tags: ["nginx", "http", "nextcloud", "documents", "nomad"]
---

# Overview

This is a Nextcloud on ```nginx``` jail that can be deployed via ```nomad```.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

You should mount an outside directory that can (but does not need to) contain a ```nextcloud``` installation into ```/usr/local/www/nextcloud```. If the directory is empty, ```nextcloud``` is installed when the jail is started and it can be configured through the normal ```nextcloud``` configuration website that is shown when it is started the first time. That means if the instance is discarded and restarted by ```nomad``` later on, the ```nextcloud``` instance that has been installed will be reused.

If there already is a ```nextcloud``` installation present, only ```nginx``` is started so that all following updates of Nextcloud can be done through the web gui itself.

Since the service is expected to be published via ```consul``` and a web proxy like ```traefik```, plus frontend ```haproxy``` no HTTPS configuration is specified in ```nginx``` as it is expected that this is happening in the web proxy. HTTPS is merely enabled.

# ZFS datasets
Make sure to create the ZFS datasets beforehand, adapt to your data set naming convention:
```
zfs create data
zfs create data/jaildata
zfs create data/jaildata/nextcloud_basic
zfs create data/jaildata/nextcloud_files
```

`nextcloud_basic` is where the nextcloud files are installed and is mounted to `/usr/local/www/nextcloud/` inside the image.

`nextcloud_files` is where the files will be kept, and is mounted to `/mnt/filestore` or similar inside the image.

# Installation
When you first run the image you'll need to setup Nextcloud via the web interface, or cli.

Make sure to specify `/mnt/filestore` or similar for DATADIR parameter (-d) in the web interface for Nextcloud setup too by clicking the dropdown for database and storage.

If you have S3 object storage with a self-signed certificate, set the SELFSIGNHOST parameter to ```ip:port``` or pass in ```-s ip:port```.

You must also copy-in the `rootca.crt` certificate from the setup of self-signed certificates for S3.

## Custom objectstore.config.php
If you wish to make use of object storage for file backing you will need to copy-in a custom `objectstore.config.php` to `/root/objectstore.config.php`.

A sample would look like the following, however please pull your source file from a working instance and include the relevant S3 parameters:

```
<?php
$CONFIG = array (
  'objectstore' => array (
    'class' => '\\OC\\Files\\ObjectStore\\S3',
    'arguments' => array(
      'bucket' => '<your-bucket>',
      'autocreate' => true,
      'key'    => '<your-key>',
      'secret' => '<your-secret>',
      'hostname' => '<your host>',
      'port' => '<your port>',
      'use_ssl' => true,
      'region' => 'optional',
      'use_path_style' => true
    ),
  ),
);
```

Take note: the addition of an objectstore array in will stop the mounted-in filestore from working.

## Custom mysql.config.php
If you wish to pre-configure MySQL settings you can copy-in a custom `mysql.config.php` to `/root/mysql.config.php`.

A sample would look like the following:

```
<?php
$CONFIG = array (
  'dbtype' => 'mysql',
  'version' => '',
  'dbname' => '<your-database-name>',
  'dbhost' => '<ip>:<port>',
  'dbtableprefix' => 'oc_',
  'dbuser' => '<db-user>',
  'dbpassword' => '<db-pass>',
  'mysql.utf8mb4' => true,
);
```

## Custom custom.config.php
If you have other settings you'd like to preconfigure you can copy in a custom `custom.config.php` to `/root/custom.config.php`.

A sample may look like the following:
```
<?php
$CONFIG = array (
  'apps_paths' =>
  array (
    0 =>
    array (
      'path' => '/usr/local/www/nextcloud/apps',
      'url' => '/apps',
      'writable' => true,
    ),
    1 =>
    array (
      'path' => '/usr/local/www/nextcloud/apps-pkg',
      'url' => '/apps-pkg',
      'writable' => false,
    ),
  ),
  'logfile' => '/mnt/filestore/nextcloud.log',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'trusted_domains' =>
  array (
    0 => '10.0.0.2',
    1 => 'my.host.name',
  ),
  'datadirectory' => '/mnt/filestore',
  'overwrite.cli.url' => 'https://my.host.name',
  'overwritehost' => 'my.host.name',
  'overwriteprotocol' => 'https',
  'theme' => '',
  'loglevel' => 0,
);
```

## Nomad Job File

A sample nomad job file is included here, and includes an optional copy-in step for a custom config.php. Remove if not used.

```
job "nextcloud" {
  datacenters = ["datacentre"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 20900
      }
    }

    task "nextcloud1" {
      driver = "pot"

      restart {
        attempts = 3
        delay    = "30s"
      }

      service {
        tags = ["nginx", "www", "nextcloud"]
        name = "nextcloud-server"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "300s"
            timeout  = "30s"
          }
          check_restart {
            limit = 0
            grace = "60s"
            ignore_warnings = false
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nextcloud-nginx-nomad"
        pot = "nextcloud-nginx-nomad-amd64-14_0"
        tag = "0.95"
        command = "/usr/local/bin/cook"
        args = ["-d","/mnt/filestore","-s","host:ip"]
        copy = [
          "/path/to/custom/objectstore.config.php:/root/objectstore.config.php",
          "/path/to/custom/mysql.config.php:/root/mysql.config.php",
          "/path/to/custom/custom.config.php:/root/custom.config.php",
          "/path/to/rootca.crt:/root/rootca.crt",
        ]
        mount = [
         "/mnt/data/jaildata/nextcloud_basic:/usr/local/www/nextcloud",
         "/mnt/data/jaildata/nextcloud_files:/mnt/filestore",
        ]
        port_map = {
          http = "80"
        }
      }

      resources {
        cpu = 1000
        memory = 2000
      }
    }
  }
}
```

# Warnings

This is a very large pot image. The nomad job will timeout on first run as `pot` takes a while to download the image and add it.

The image boots with https enabled in nginx. You will need a frontend proxy like `haproxy` or `traefik` or similar to handle the redirect from a domain name, with SSL, to the internal nomad host and port configured in job file. A valid digital certificate would be useful too.

## Self-signed SSL for Object storage

Pass in a ```ip:port``` paramater for ```SELFSIGNHOST``` or ```-s ip:port```. If you don't specify a port 443 will be used.

You also need to copy-in the `rootca.crt` file created as part of setting up self-signed certificates. Make sure to copy-in to `/root/rootca.crt` as the script expecting this file name.

# Useful CLI admin commands

The following commands can be entered in via the command line, from the pot host with

```
pot term nextcloud_id...
```

## Get the LDAP config
```
su -m www -c 'php /usr/local/www/nextcloud/occ ldap:show-config'
su -m www -c 'php /usr/local/www/nextcloud/occ ldap:show-config' |grep -e ldapHost -e ldapBase
```

## Set a new LDAP server
Get the value in the top row of command above, ```Configuration```, should be something like ```s01``` and set your new LDAP host with
```
su -m www -c 'php /usr/local/www/nextcloud/occ ldap:set-config s01 ldapHost 10.0.0.2'
```
or possibly scripted like follows:
```
myhost=10.0.0.2
myconfig=$(su -m www -c 'php /usr/local/www/nextcloud/occ ldap:show-config' | grep -e "| Configuration" | awk -F"|" '{print $3}' | sed 's/^ //g')
su -m www -c "php /usr/local/www/nextcloud/occ ldap:set-config ${myconfig} ldapHost ${myhost}"
```

## Perform basic maintenance to fix errors with layout or stylesheets
```
su -m www -c 'php /usr/local/www/nextcloud/occ maintenance:repair'
```

## Get a list of all possible commands
```
su -m www -c 'php /usr/local/www/nextcloud/occ list'
```
