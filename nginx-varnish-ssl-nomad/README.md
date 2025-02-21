---
author: "Bretton Vine"
title: NGINX Varnish SSL website (Nomad)
summary: This is a jail preconfigured with NGINX SSL to Varnish backend for Minio that can be deployed via nomad.
tags: ["nginx", "http", "varnish", "ssl", "objectstore", "nomad"]
---

# Overview

This is a ```nginx``` jail that can be deployed via ```nomad```.

You need to pass in the ip:port of the `varnish` server, and bucket name for s3 objectstore, and `nginx` will serve the files from that bucket by way of the `varnish` host.

A suitable `varnish` jail would be `haproxy-minio` which includes `varnish` on port `8080`, and must be configured to connect to minio.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

Since the service is expected to be published via ```consul``` and a web proxy like ```traefik```, plus frontend ```haproxy``` no HTTPS configuration is specified in ```nginx``` as it is expected that this is happening in the web proxy. HTTPS is merely enabled.

# Installation

## Secure front end
This image runs on port 443 with a self-signed certificate, and connects to varnish over clear text HTTP. It is expected that this image will be behind a secure proxy.

To enable HTTPS on the public frontend, make sure to use a solution like `haproxy` with `acme.sh` for the public domain name, and proxy through to this image.

# Options
You can pass in parameters to set variables.

DOMAIN is the domain name to use for self-signed certificate used by nginx. You can set this option with `-d` and the domain name.

SERVERPORT is the ip:port of the varnish server. You can set this option with `-s` and `ip:port`. 

BUCKET is the name of the bucket to access, and can be set with `-b` and the bucket name.

# Nomad Job File Samples

The following example job is provided:
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
        name = "nginx-varnish-service"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/nginx-varnish-ssl-nomad"
        pot = "nginx-varnish-ssl-nomad-amd64-14_2"
        tag = "0.5.1"
        command = "/usr/local/bin/cook"
        args = ["-d","domainname","-s","10.0.0.2:8080","-b","bucketname"]
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
