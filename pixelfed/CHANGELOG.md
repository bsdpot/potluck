0.5

* Version bump for new base image

---

0.4

* Version bump for new base image
* Adjust for php-fpm/php_fpm in RC service

---

0.3

* Version bump for new base image
* Set .env variable "FILESYSTEM_DRIVER=s3"
* Switch to latest package stream
* Build as non-layered image
* Add script to help with laravel.log

---

0.2

* Version bump for new base image
* Python is now py311
* Update cache clear script

---

0.1

* Version bump for new base image

---

0.0

* First bash at a pot jail for pixelfed
* Fix typos
* Fix env file formatting
* Redis must be running before pixelfed is configured, optionally user www must be part of redis group
* Add www user to redis group
* Remove redis socket in favour of remote redis jail over tcp
* Postgresql databases aren't automatically created, we need a step to do this
* Remove horizon:publish step as no longer needed
* Adjust database creation process
* Properly fix prior fix with db create step and error return codes
* Ensure nginx root has correct directory with public appended in all places
* Ensure port 80 bound to ip
* Add script to create admin user
* Make sure /usr/local/www/acmetmp/ is created for both SSL options
* Add ffmpeg to packages
* Adjust pixelfed env parameters and add steps to migrate2cloud
* Adjust pixelfed env parameters
* Adjust admin user creation script
* Try more recent commit of pixelfed to get working admin dashboard
* Add script to clear cache
* Modify parameters for supervisord and cron to remove ansi
* Adjust admin user creation script so username is not an email address
* Cleanup nginx formatting and minor adjustments
* Adjustments to pixelfed setup to try get admin dashboard to show
* Revert to prior setup for user creation. db records 'f'. 
* Fixed admin user creation script, use true or false, not yes/no or 1/0.
* Don't quote mail or S3 parameters in pixelfed env
* S3 posting URL needs bucketname too
* Remove old redis.conf template as not in use
* Add blackbox_exporter
* Update certificate renewal script
