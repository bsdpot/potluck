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
