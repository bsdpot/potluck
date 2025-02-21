---
author: "Bretton Vine"
title: Caddy s3 website (Nomad)
summary: This is a jail preconfigured with Caddy configured for s3 that can be deployed via nomad.
tags: ["caddy", "http", "s3", "objectstore", "nomad"]
---

# Overview

This is a ```caddy``` jail that can be deployed via ```nomad```.

You need to pass in the IP addresses and bucket name for s3 objectstore, and `caddy` will serve the files.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

Since the service is expected to be published via ```consul``` and a web proxy like ```traefik```, plus frontend ```haproxy``` no HTTPS configuration is specified in ```nginx``` as it is expected that this is happening in the web proxy. HTTPS is merely enabled.

# Installation

## Prepare Minio
A minio bucket needs to exist with the website content before running this image.

This image will automatically load-balance between multiple minio servers for this specific bucket.

```
# set minio variables
env MINIO_ACCESS_KEY="ACCESSKEY"
env MINIO_SECRET_KEY="PASSWORD"

# set alias
minio-client alias set minio1 https://x.x.x.x:9000 ACCESSKEY PASSWORD --api S3v4  --insecure --config-dir /root/.minio-client/

# create default bucket
minio-client --insecure mb --config-dir /root/.minio-client/ --with-lock minio1/default

# create website bucket
minio-client --insecure mb --config-dir /root/.minio-client/ minio1/website-bucket

(todo: add steps for authentication)

# set anonymous download policy
minio-client --insecure policy set download minio1/website-bucket

# recursively copy website files to bucket
minio-client --insecure cp -r /path/to/website minio1/website-bucket/
```

## Secure front end
This image runs on port 443, with automatic certificate management. It is expected to be run behind a proxy.

# Options
You can pass in parameters to the image to set variables.

BUCKET is the name of the bucket to access, and can be set with `-b` and the bucket name.

DOMAIN is the domain name of the site. You can set this with the `-d` parameter and the domain name.

EMAIL is the email address to use for SSL certificate registration. You can set this with the `-e` parameter and email address.

SERVER is the S3 server. You can also set this with the `-h` parameter followed by the S3 host..

SELFSIGNED is optional and enables obtaining the self-signed CA certicate from minio into the local store. Enable with `-s` and any value.

ALERTIP is an optional parameter for the IP address of an `alertmanager` instance, for sending notices of certificate expiry.

# Nomad Job File Samples

The following example job uses 1 self-signed minio server.

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 28000
      }
    }

    task "www1" {
      driver = "pot"

      service {
        tags = ["caddy", "www"]
        name = "caddy-s3-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/caddy-s3-nomad"
        pot = "caddy-s3-nomad-amd64-14_2"
        tag = "0.19.1"
        command = "/usr/local/bin/cook"
        args = ["-h","s3.my.host","-b","bucketname","-d","domainname","-e","email@add.com","-s","yes","-x","alertmanager-ip"]
		mount = [
          "/path/to/dataset/caddyimage:/mnt"
        ]
        port_map = {
          http = "443"
        }
      }

      resources {
        cpu = 200
        memory = 64
      }
    }
  }
}
```

Make sure the mounted-in dataset exists, SSL certificate files are saved to /mnt.
