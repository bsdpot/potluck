0.117

* Version bump for new image

---

0.116

* Version bump for new image with pkg 2
* Quote PATH statements

---

0.113

* Version bump for new quarterlies
* Update for rsync security issue
* Fix switch to latest over quarterly

---

0.112

* Include proxy.config.php option for setting trusted proxies
* Adjustments to php config to match suggested
* Switch to php83

---

0.111

* Add package php82-pgsql and document related changes

---

0.110

* Rebuild for 14.2

---

0.109

* Testing: remove special patches as post-install nextcloud integrity checker might be failing on the patches to add 'no ssl verify' for object storage

---

0.108

* Fix php socket path for caddy
* Add parameter to php-fpm for NEXTCLOUD_CONFIG_DIR

---

0.107

* Enable option to use caddy instead of nginx
* Add autoconfig.php logic

---

0.106

* Enable option openssl.cafile permenantly in php custom config

---

0.105

* Experimental adjustments to nginx and php

---

0.104

* Version bump for new image

---

0.103

* Version bump for FBSD 14.1
* Extra steps to trim image size

---

0.102

* Version bump for new image
* Add option to install nextcloud from github instead of packages

---

0.101

* Version bump for new image
* Adjust for php-fpm/php_fpm in RC service

---

0.100

* Version bump for new image
* Adjust permissions on copied in files for install
* Include nextcloud-talk in nextcloud packages

---

0.99

* Version bump for new image
* Fix warning for javascript mime-types adjustment

---

0.98

* Version bump for new image
* Move enabling php-fpm service to manual step after creating missing rc file

---

0.97

* Version bump for new image

---

0.96

* Version bump for rebuild
* Increase S3 timeout value in docs

---

0.95

* Version bump for rebuild

---

0.94

* Version bump for new nextcloud

---

0.93

* Version bump for new quarterlies

---

0.92

* Version bump for rebuild
* Add storage to build host

---


0.91

* Version bump for rebuild

---

0.90

* Version bump for FBSD14

---

0.89

* Add missing js mimetype

---

0.88

* Version bump for rebuild
* Add php82-sodium

---

0.87

* Version bump for rebuild

---

0.86

* Version bump for rebuild

---

0.85

* Version bump for new version nextcloud
* Use ImageMagick7 instead of ImageMagick6-nox11 and install all X dependencies too, because php82-pecl-imagick

---

0.84

* Version bump for security updates in base

---

0.83

* Version bump for new packages

---

0.82

* Set X-Robots-Tag to "noindex, nofollow"

---

0.81

* Update to php82 versions of everything

---

0.80

* Include php package php81-sysvsem

---

0.79

* Rebuild for bsd and package updates

---

0.78

* Rebuild for pkg updates

---

0.77

* Rebuild for failed build
* php81-pecl-memcached is now php81-pecl-memcache

---

0.76

* Version bump for new quarterlies

---

0.75

* Version bump to rebuild for 13.2
* Still using php81 versions

---

0.74

* Version bump for rebuild
* Signify enabled

---


0.73

* Version bump for new base image
* Signified

---

0.72

* Version bump for rebuild
* Experimental NGINX change to include backlog and reuseport

---

0.71

* Version bump for rebuild

---

0.70

* Version bump for rebuild

---

0.69

* Version bump for rebuild

---

0.68

* Version bump for new base image

---

0.67

* nextcloud-twofactor_totp is included in base nextcloud package from v25.0.1 on

---

0.66

* Non-layered version with latest package sources

---

0.65

* php81 versions of nextcloud

---

0.64

* Fix nextcloud versions nextcloud-php80-* with dependancies on php80
* Incorrectly assumed php82 versions of nextcloud after checking all the other php package names

---

0.63

* Bump to php82 versions of nextcloud

---

0.62

* Remove default nextcloud config.php
* x.y.z versioning numbering not implemented yet for this image

---

0.61

* Improved process for new installs
* Copy in multiple config files
* Update README

---

0.60

* Version bump for rebuild

---

0.59

* Version bump for rebuild! fails to export

---

0.58

* Version bump for rebuild

---

0.57

* Version bump for rebuild again

---

0.56

* Version bump for rebuild

---

0.55

* Version bump for rebuild to fix missing images on potluck site

---

0.54

* Version bump for p3 rebuild

---

0.53

* Updating php-fpm config
* Adding www.conf.in file
* openldap26-client

---

0.52

* Formatting in new patch file, add comma

---

0.51

* Tabs and newline in new patch file for no-ssl-verify

---

0.50

* Remove erroneous log statement

---

0.49

* Make patching nextcloud a specific option
* Set non-verify parameters in new fashion

---

0.48

* Patch file path fix

---

0.47

* Comment out newwww group changes, not using fusemounts
* Split configure-nextcloud.sh into multiple mini-scripts to isolate problems

---

0.46

* Unquote "0" for group check

---

0.45

* Need a check for group existing

---

0.44

* Simplify start of php-fpm and nginx due to crash error

---

0.43

* Reorder items
* Add checklist for changes
* First-time runs of image may bomb out when nomad restarts it, but pkg install still happening

---

0.42

* Trying different approach copying in self-signed rootCA file
* If you generated self-signed certs, you'll have the file to copy in

---

0.41

* Openssl s_client expects (no)servername flag

---

0.40

* Undo pkg fetch, make sure to run pkg update

---

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
