---
author: "Bretton Vine"
title: NGINX s3 SSL website (Nomad)
summary: This is a jail preconfigured with NGINX SSL configured for s3 that can be deployed via nomad.
tags: ["nginx", "http", "s3", "ssl", "objectstore", "nomad"]
---

# Overview

This is a ```nginx``` jail that can be deployed via ```nomad```.

You need to pass in the ip:port and bucket name for s3 objectstore, and `nginx` will serve the files from that bucket.

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

# set anonymous download policy
minio-client --insecure policy set download minio1/website-bucket

# recursively copy website files to bucket
minio-client --insecure cp -r /path/to/website minio1/website-bucket/
```

## Secure front end
This image runs on port 443 with a self-signed certificate, and connects to minio with SSL, even if it also has a self-signed certificate. It is expected that this image will be behind a secure proxy.

To enable https on the frontend, make sure to use a solution like `haproxy` with `acme.sh` for the public domain name, and proxy through to this image.

# Options
You can pass in parameters to the image to set variables.

DOMAIN is the domain name to use for self-signed certificate used by nginx. You can set this option with `-d` and the domain name.

SERVERONE is the first minio server. SERVERTWO is the second. SERVERTHREE is the third. You must pass in `ip:port` for each value. You can set one or all of these with options `-e`, `-f`, `-g-` and `-h` for each server.

BUCKET is the name of the bucket to access, and can be set with `-x` and the bucket name. 

SELFSIGNED enables obtaining the minio self-signed CA certicate into the local store. Enable with `-s` and any value. This image will generate a self-signed certificate for nginx by default.

# Nomad Job File Samples

## Single Minio server

The following example job uses a single minio servers and a self-signed host.

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 28443
      }
    }

    task "www1" {
      driver = "pot"

      service {
        tags = ["nginx", "www"]
        name = "nginx-s3-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nginx-s3-ssl-nomad"
        pot = "nginx-s3-ssl-nomad-amd64-14_2"
        tag = "0.14.1"
        command = "/usr/local/bin/cook"
        args = ["-d","domainname","-e","10.0.0.2:9000","-x","bucketname","-s","yes"]
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

## Two Minio servers

The following example job uses 2 minio servers and a self-signed host.

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 28443
      }
    }

    task "www1" {
      driver = "pot"

      service {
        tags = ["nginx", "www"]
        name = "nginx-s3-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nginx-s3-ssl-nomad"
        pot = "nginx-s3-ssl-nomad-amd64-14_2"
        tag = "0.14.1"
        command = "/usr/local/bin/cook"
        args = ["-d","domainname","-e","10.0.0.2:9000","-f","10.0.0.3:9000","-x","bucketname","-s","yes"]
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

## Four Minio Servers

The following example job uses a maximum of 4 minio servers and a self-signed host.

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    network {
      port "http" {
        static = 28443
      }
    }

    task "www1" {
      driver = "pot"

      service {
        tags = ["nginx", "www"]
        name = "nginx-s3-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nginx-s3-ssl-nomad"
        pot = "nginx-s3-ssl-nomad-amd64-14_2"
        tag = "0.14.1"
        command = "/usr/local/bin/cook"
        args = ["-d","domainname","-e","10.0.0.2:9000","-f","10.0.0.3:9000","-g","10.0.0.4:9000","-h","10.0.0.5:9000","-x","bucketname","-s","yes"]
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
