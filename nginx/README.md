---
author: "Luca Pizzamiglio & Stephan Lichtenauer"
date: 2020-05-09
title: NGINX
tags: ["nginx", "http", "httpd", "web server"]
---

# Overview

This is a basic NGINX jail.

NGINX is started (as usually) as a daemon when the jail is started which means that this jail is not for use with ```pkg install nomad``` but for "normal" use with ```pot start```.
