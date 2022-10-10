0.39

* Pkg fetch nextcloud packages early on, include as local in package cache

---

0.38

* For fresh installs, force pkg update before installing nextcloud

---

0.37

* Completely remove syslog-ng as not working with nomad pots
* fix nc-config.php setup, needs manual copy-in

---

0.36

* Version bump for rebuild
* Adding OPTIND to getopts
* Fixing .env.cook with if statement
* Remove ssh disable as done in base

---

0.35

* fixing copy-in to reflect nextcloud-nginx-nomad flavour not freebsd-potluck

---

0.34

* Setting runs in nomad correctly all over
* Increment version in README nomad job

---

0.33

* Version bump for rebuild
* Correct README added back from previous cook format image
* README update for version in job file

---

0.32

* Update image to use newer cook format
* Rebuild for layered images again

---

0.31

* Version bump to build a non-layered image

---

0.30

* Nginx improvements for proxy and fastcgi timeouts
* Adjust php-fpm and nginx start again, restart loops with failure for nginx

---

0.29

* Trial with php80
* Fixed README for job file version and FreeBSD version
* Using pkill to stop nginx and replace a kill pgrep pipe
* Adjusting start process for php-fpm and nginx to use restart

---

0.28

* Missing 'then' in if statement
* Fixed CHANGELOG versioning

---

0.27

* Revert to php74-* and next update do the php82 change
* Remove syslogd, replace with syslog-ng

---

0.26

* Setting cron job to every 15mins because no checks if existing job running
* revert to ImageMagick6-nox11 for testing

---

0.25

* Version bump for FreeBSD-13.1 image
* php74-* to php82-*
* no more php82-openssl, possibly in php core
* no more php82-json, in php core
* ImageMagick7-nox11 instead of ImageMagick6-nox11

---

0.24

* Replacing package ImageMagick7 with ImageMagick6-nox11
* Removing php74-pHash due to conflicts
* Fixing version in nomad job file in readme missed last update
* Adding package libheif
* Fixing occache setup in php.ini extra file

---

0.23

* Adding package ImageMagick7, php74-mysqli
* Additions to php.ini extra file

---

0.22

* Fixing nginx and php-fpm problems

---

0.21

* Updates to nginx.conf copy in
* Adding missing packages for php libraries
* Added cron job to /etc/crontab

---

0.20

* Added ocdata dotfile setup

---

0.19

* Include self-signed CA cert in nextcloud files

---

0.18

* Improved patch file

---

0.17

* Patch nextcloud for self-signed S3 if self-signed var enabled

---

0.16

* Enable fopen for php
* Enable apc.enable_cli for php
---

0.15

* Include basic cli admin scripts
* Set php error log

---

0.14

* Add nextcloud logs with www perms
* Added mechanism to import self-signed cert for libcurl usage

---

0.13

* Check for presence of /root/nc-config.php and copy to /usr/local/www/nextcloud/config/config.php if exists, to allow for custom config setup

---

0.12

* Adjust start process for php-fpm and nginx, rebuild for latest packages
* Fixup nomad job file example

---

0.11

* Rebuild for new potluck template and other changes

---

0.10

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

0.9

* Adding -9 to killall command as nginx not restarting correctly. Including setting of www perms, removing tweak for S3 mounts.

---

0.8

* Fixing bad path for php-fpm again

---

0.7

* Fixing bad path for php-fpm from nextcloud docs in reorg

---

0.6

* Re-organising nginx.conf as per nextcloud docs

---

0.5

* Fixing php-fpm config to use socket, old sed didn't work

---

0.4

* Enabling php errors in browser, improvements and fixes to nginx.conf. Adding memcached.

---

0.3

* Correcting nginx.conf as documented parts don't work

---

0.2

* Fixing path for copy in of config files

---

0.1

* First release nextcloud flavour

---

0.0

* Initial commit
