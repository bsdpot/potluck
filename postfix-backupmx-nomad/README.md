---
author: "Stephan Lichtenauer"
title: Postfix Backup MX (Nomad)
summary: This is a Postfix jail preconfigured as backup MX that can be deployed via nomad.
tags: ["postfix", "smtpd", "backup mx", "mail server", "nomad"]
---

# Overview

This is a Postfix jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

For more details about ```nomad``` images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).

The jail exposes these parameters that can either be set via the environment or by setting the ```cook```parameters (the latter either via ```nomad```, see example below, or by editing the downloaded jails ```pot.conf``` file):

| Environment      | cook parameter     | Content      |
| :--------------- | :----------------: | :-----------|
| HOSTNAME       | -h              | ```myhostname``` in ```main.cf``` |
| MYNETWORKS       | -n                 | ```mynetworks``` in ```main.cf``` (private network addresses that are permitted to send outbound) |
| RELAYDOMAINS       | -d                 | ```relay_domains``` in ```main.cf``` (domains this server feels responsible for) |
| SMTPDBANNER       | -b               | ```smtpd_banner``` in ```main.cf``` |

*Note: If you schedule this jail via ```nomad``` **and you do not mount in the spool directory from persistent storage like in the example below** and the job gets restarted for whatever reason, mails that are still in the queue and not forwarded will not be part of the newly scheduled instance and will be lost because a completely new jail is created in that case.*


# Nomad Job Description Example

Example with passing parameters to the ```cook``` script and mounting a persistent spool directory to ensure that mails are not discarded on job restarts:

```
job "backupmx" {
  datacenters = ["mydc"]
  type        = "service"

  group "group1" {
    count = 1

    task "backupmx1" {
      driver = "pot"

      service {
        tags = ["backupmx", "postfix"]
        name = "backupmx"
        port = "smtp"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      config {
        image = "https://potluck.honeyguide.net/postfix-backupmx-nomad"
        pot = "postfix-backupmx-nomad-amd64-14_2"
        tag = "1.22.1"
        command = "/usr/local/bin/cook"
        args = ["-n","10.10.10.10/32","-d","'example1.com, example2.com, example.de'","-b","'mx2.example1.com ESMTP \\$mail_name'","-h","mx2.example1.com"]
        mount = [
          "/mnt/spool:/var/spool/postfix"
        ]

        port_map = {
          smtp = "25"
        }
      }

      resources {
        cpu = 200
        memory = 64

        network {
          mbits = 10
          port "smtp" {
            static = 25000
          }
        }
      }
    }
  }
}
```

Example with passing parameters via environment variables (not working with pot 0.11.2 or below due to a bug):

```
job "backupmx" {
  datacenters = ["mydc"]
  type        = "service"

  group "group1" {
    count = 1

    task "backupmx1" {
      driver = "pot"

      service {
        tags = ["backupmx", "postfix"]
        name = "backupmx"
        port = "smtp"

         check {
            type     = "tcp"
            name     = "tcp"
            interval = "60s"
            timeout  = "30s"
          }
      }

      env {
        MYNETWORKS = "10.10.10.10/32"
        RELAYDOMAINS = "'example1.com, example2.com, example.de'"
        SMTPDBANNER = "'mx2.example1.com ESMTP \\$mail_name'"
        HOSTNAME = "mx2.example1.com"
       }
       config {
        image = "https://potluck.honeyguide.net/postfix-backupmx-nomad"
        pot = "postfix-backupmx-nomad-amd64-14_2"
        tag = "1.22.1"
        command = "/usr/local/bin/cook"
        args = [""]

        port_map = {
          smtp = "25"
        }
      }

      resources {
        cpu = 200
        memory = 64

        network {
          mbits = 10
          port "smtp" {
            static = 25000
          }
        }
      }
    }
  }
}
```
