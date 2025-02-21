---
author: "Bretton Vine"
title: NGINX s3 website (Nomad)
summary: This is a jail preconfigured with NGINX configured for s3 that can be deployed via nomad.
tags: ["nginx", "http", "s3", "objectstore", "nomad"]
---

# Overview

This is a ```nginx``` jail that can be deployed via ```nomad```.

You need to pass in the IP addresses and bucket name for s3 objectstore, and `nginx` will serve the files.

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
This image runs on port 80, and connects to minio with SSL, even if self-signed certificate. It is expected to be run behind a secure proxy.

To enable https on the frontend, make sure to use a solution like `haproxy` with `acme.sh` for the public domain name, and proxy through to this image.

# Options
You can pass in parameters to the image to set variables.

SERVERONE is the first minio server. SERVERTWO is the second. SERVERTHREE is the third. You can set one or all of these with options `-a`, `-b`, and `-c`, for each server.

BUCKET is the name of the bucket to access, and can be set with `-x` and the bucket name. 

SELFSIGNED enables obtaining the self-signed CA certicate into the local store. Enable with `-s` and any value.

# Nomad Job File Samples

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
        static = 28000
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
        image = "https://potluck.honeyguide.net/nginx-s3-nomad"
        pot = "nginx-s3-nomad-amd64-14_2"
        tag = "0.25.1"
        command = "/usr/local/bin/cook"
        args = ["-a","10.0.0.2","-b","10.0.0.3","-x","bucketname","-s","yes"]
        port_map = {
          http = "80"
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

## Three Minio Servers

The following example job uses a maximum of 3 minio servers and a self-signed host.

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
        image = "https://potluck.honeyguide.net/nginx-s3-nomad"
        pot = "nginx-s3-nomad-amd64-14_2"
        tag = "0.25.1"
        command = "/usr/local/bin/cook"
        args = ["-a","10.0.0.2","-b","10.0.0.3","-c","10.0.0.4","-x","bucketname","-s","yes"]
        port_map = {
          http = "80"
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
