---
author: "Luca Pizzamiglio & Stephan Lichtenauer"
title: NGINX
summary: This is a basic NGINX jail, NGINX is started (as usually) as a daemon.
tags: ["nginx", "http", "httpd", "web server"]
---

# Overview

This is a basic NGINX jail.

NGINX is started (as usually) as a daemon when the jail is started which means that this jail is not for use with nomad (```pkg install nomad```) but for "normal" use with ```pot start```.
