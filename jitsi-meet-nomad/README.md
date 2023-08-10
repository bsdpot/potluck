---
author: "Stephan Lichtenauer"
title: Jitsi Meet (Nomad)
summary: This is a complete JITSI MEET instance that can be deployed via nomad.
tags: ["jitsi", "jitsi-meet", "video conference", "nomad"]
---

# Overview

This is a complete ```jitsi-meet``` installation in one jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

The jail configures itself on the first start for your environment (see notes below), for details about how to run ```jitsi-meet``` in a FreeBSD jail in general, see [this blog post](https://honeyguide.eu/posts/jitsi-freebsd/).

NGINX is started as blocking task when the jail is started, all other services are started as services.

Deploying the image or flavour should be quite straight forward and not take more than a few minutes.

## Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/jitsidata zroot/jitsidata```
* Add an adjusted nomad job file to nomad to run

## Parameters

NODENAME is the name of this node (-n name)

DOMAIN is the domain name of the jitsi instance (-d jitsi.honeyguide.net)

PUBLICIP is the public IP address of the jitsi instance (-p 1.2.3.4)

PRIVATEIP is the local interface the jail is running on (-q 10.0.0.2)

RESOLUTION is one of the valid [jitsi-meet resolution settings](https://github.com/jitsi/lib-jitsi-meet/blob/master/service/RTC/Resolutions.js) such as `180`, `240`, `360`, `480`, `720`, `fullhd` etc. (-r 360)

## Optional Parameters

IMAGE is the filename of an image copied in to `/usr/local/www/jitsi-meet/images/{filename}` (-i filename.jpg)

LINK is the full URL with `https://full.url/path` to link the custom logo to.

## Nomad Job Description Example
This is a nomad job file to use as a starting point.

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    task "wwwjitsi" {
      driver = "pot"

      service {
        tags = ["nginx", "www", "jiti-meet"]
        name = "jitsi"
        port = "http"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
          check_restart {
            limit = 5
            grace = "120s"
            ignore_warnings = false
          }
      }

      env {
        DOMAIN = "jitsi.honeyguide.net"
        ALERTEMAIL = "user@example.com"
      }
      config {
        image = "https://potluck.honeyguide.net/jitsi-meet-nomad/"
        pot = "jitsi-meet-nomad-amd64-13_2"
        tag = "2.1.1"
        command = "/usr/local/bin/cook"
        args = [""]

        copy = [
         "/path/to/image.jpg:/root/image.png"
        ]
        mount = [
         "/mnt/jitsidata:/mnt"
        ]
        port_map = {
          http = "80"
        }
      }

      resources {
        cpu = 1000
        memory = 1024

        network {
          mbits = 10
          port "http" {}
        }
      }
    }
  }
}
```
