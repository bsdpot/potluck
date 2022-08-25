---
author: "Stephan Lichtenauer, Bretton Vine"
title: Matrix Synapse (Nomad)
summary: Matrix Synapse secure, decentralised, real-time communication server that can be deployed via nomad.
tags: ["matrix", "synapse", "im", "instant messaging", "nomad"]
---

# Overview

**IMPORTANT NOTE: THIS IS A BETA IMAGE!**

This instance uses `sqlite` instead of `postgres` and may not be suitable for busy servers.

This is a Matrix Synapse jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

# Setup
You must run your matrix instance from a top level domain such as example.com, not matrix.example.com.

This is a quirk of using .well-known/matrix/server with the server's details.

## Installation

* Create a ZFS data set on the parent system beforehand
  ```zfs create -o mountpoint=/mnt/matrixdata zroot/matrixdata```
* Add an adjusted nomad job file to nomad to run

## Parameters

IP is the IP address of the jail. (-i "10.10.10.10")

DOMAIN is the domain for synapse. (-d "domain")

ALERTEMAIL is the email address for alerts. (-a "email@example.com")

ENABLEREGISTRATION is whether to enable account registration or not. (-e "false")

MYSHAREDSECRET is the shared secret to use. (-s "secret")

SMTPHOST is the mail server to use. (-h "smtp.example.com")

SMTPPORT is the SMTP port to use. (-p "25")

SMTPUSER is the username for authenticated SMTP. (-u "username")

SMTPPASS is the password for authenticated SMTP. (-c "password")

SMTPFROM is the email from address for authenticated SMTP. (-f "email@example.com")

LDAPSERVER is the IP or domain name of the LDAP server. (-l "ldap.example.com")

LDAPPASSWORD is the password to use for LDAP. (-b "ldappassword")

LDAPDOMAIN is the domain in use by LDAP. (-t "example2.com")

NOSSL set to true disables SSL on nginx. (-n "false")

CONTROLUSER set to true enables a control user. (-x "true")

SSLEMAIL is the registration email to use with zerossl. (-y "email@example.com")

## Nomad Job Description Example
This is an untested nomad job file to use as a starting point.

```
job "example" {
  datacenters = ["datacenter"]
  type        = "service"

  group "group1" {
    count = 1

    task "www1" {
      driver = "pot"

      service {
        tags = ["nginx", "www", "matrix"]
        name = "matrix"
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
        IP = "10.10.10.10"
        DOMAIN = "example.com"
        ALERTEMAIL = "user@example.com"
        ENABLEREGISTRATION = "false"
        MYSHAREDSECRET = "sharedsecret"
        SMTPHOST = "smtp.example.com"
        SMTPPORT = "25"
        SMTPUSER = "username"
        SMTPPASS = "password"
        SMTPFROM = "user@example.com"
        LDAPSERVER = "10.10.10.20"
        LDAPPASSWORD = "ldappassword"
        LDAPDOMAIN = "ldapdomain"
        NOSSL = "false"
        CONTROLUSER = "true"
        SSLEMAIL = "user@example.com"
      }
      config {
        image = "https://potluck.honeyguide.net/matrix-synapse-nomad/"
        pot = "matrix-synapse-nomad-amd64-13_0"
        tag = "0.10.2"
        command = "/usr/local/bin/cook"
        args = [""]

        copy = [
         "/path/to/importauthkey:/root/importauthkey"
        ]
        mount = [
         "/mnt/matrixdata:/mnt"
        ]
        port_map = {
          http = "80"
          https = "443"
          matrix = "8448"
        }
      }

      resources {
        cpu = 1000
        memory = 1024

        network {
          mbits = 10
          port "http" {}
          port "https" {}
          port "matrix" {}
        }
      }
    }
  }
}
```
