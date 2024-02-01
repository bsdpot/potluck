---
author: "Deividas Gedgaudas"
title: Adminer
summary: This is a barebones adminer jail with nginx and php-fpm. A non-nomad persistent jail.
tags: ["adminer", "nginx", "php", "database"]
---

# Overview

```
Adminer (formerly phpMinAdmin) is a full-featured database management tool written in PHP. Conversely to phpMyAdmin, it consist of a single file ready to deploy to the target server.  
Adminer is available for MySQL, PostgreSQL, SQLite and Oracle.
```

This is a non-nomad persistent jail.

To modify which databases can `adminer` connect to - edit `adminer.sh L:85` and remove the ones you do not need:

```sh
step "Install PHP database extensions"
pkg install -y php82-mysqli php82-odbc php82-pgsql php82-pdo_sqlite
```
