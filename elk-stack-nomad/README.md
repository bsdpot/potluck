---
author: "Stephan Lichtenauer"
title: ELK Stack (Nomad)
summary: This is an Elasticsearch/Logstash/Kibana jail that can be deployed via nomad.
tags: ["elasticsearch", "logstash", "kibana", "monitoring", "nomad"]
---

# Overview

This is a ```elasticsearch```/```logstash```/```kibana``` (ELK)  jail that can be started with ```pot``` but it can also be deployed via ```nomad```.

The ```elasticsearch``` storage directory is in ```/var/db/elasticsearch```.    
It is suggested that this directory is mounted from outside the jail when it is run as a ```nomad``` task so that it is persistent (see example below).

The ```logstash``` configuration (```logstash.yml```, ```logstash.conf```, ```pipelines.yml```) is located in ```/usr/local/etc/logstash``` and you probably want to copy in your own configuration and potentially mount some source directories that can be accessed depending on your monitoring and aggregation needs.

The ```kibana``` web interface can be accessed via web browser through port 5601. 

For more details about ```nomad```images, see [about potluck](https://potluck.honeyguide.net/micro/about-potluck/).


# Nomad Job Description Example

```
job "elkstack" {
  datacenters = ["mydc"]
  type        = "service"

  group "group1" {
    count = 1 

    task "www1" {
      driver = "pot"

      service {
        tags = ["elkstack", "www"]
        name = "elkstack"
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

      config {
        image = "https://potluck.honeyguide.net/elk-stack-nomad"
        pot = "elk-stack-nomad-amd64-12_1"
        tag = "1.0"
        command = "/usr/local/bin/cook"
        mount = [
          "/mnt/logfiles:/mnt"
        ]
        copy = [
          "/mnt/logstash.conf:/usr/local/etc/logstash/logstash.conf",
          "/mnt/logstash.yml:/usr/local/etc/logstash/logstash.yml"
        ]
        port_map = {
          http = "5601"
        }
      }

      resources {
        cpu = 1000
        memory = 2048 

        network {
          mbits = 50
          port "http" {}
        }
      }
    }
  }
}
```


