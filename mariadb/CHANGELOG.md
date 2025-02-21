4.14

* Version bump for new base image

---

4.13

* Version bump for new base image
* Quote PATH statements

---

4.12

* Version bump for new base image
* Update for rsync security issue

---

4.11

* Version bump for new base image 14.2

---

4.10

* Version bump for new base image
* Enable milliseconds in syslog-ng for all log timestamps
* Update syslog-ng config to use modern config options
* Set mariadb expire_logs_days option

---

4.9

* Version bump for new base image 14.1
* Extra steps to trim image size

---

4.8

* Version bump for new base image

---

4.7

* Version bump for new base image

---

4.6

* Version bump for new base image

---

4.5

* Version bump for new base image

---

4.4

* Version bump for new base image
* Fix node_exporter zfs issue

---

4.3

* Version bump for new base image
* FBSD14 base image

---

4.2

* Version bump for new base image

---

4.1

* Version bump for new base image

---

4.0

* Version bump for new base image

---

3.9

* Version bump for new base image

---

3.8

* Version bump for new base image

---

3.7

* Version bump for introduction of replication
* Add parameters to setup server_id, replication credentials, and scripts for easy slave configuration
* Minor tweaks to ignore minor errors, also testing master-slave and master-master works
* Add --disable-log-bin in mysql_install_db_args in mysql-server rc script
* Fix error in changing mysql-server rc script
* Add GALERAHOST parameter to set an access rule for a loadbalancer host
* Rename GALERAHOST to LOADBALANCER, galera user to haproxy, to avoid confusion with galera package
* Add relay-log to avoid replication problems on hostname change
* Rename configure-galerauser.sh file and fix typos
* Fix parameter names in README
* mysqld_exporter runs as user nobody but config file with password has restrictive permissions, fixed

---

3.6

* Version bump for new base image
* mariadb105 to mariadb106
* Fix syslog-ng problems for 4.2 version, remove stats_freq option
* Add local unbound for consul DNS resolution
* Minor change to consul agent config to use retry_join instead of start_join
* Add service to consul setup
* Fix addition of services
* Add consul DNS info to README
* fix local_unbound dns resolution with missing parameters for access control
* Disable consul DNS option with local_unbound as is only practical in VNET jails with a localhost
* Duplicate mysqld_exporter mariadb user with localhost access for VNET jails
* Adjust above step for 127.0.0.1 and ::1

---

3.5

* Version bump for new base image

---

3.4

* Version bump for new base image
* Signified
* Fix nologin shell for nodeexport user

---

3.3

* Version increment for new feature
* Pass consul servers in as a comma-deliminated list of IP addresses

---

3.2

* Version bump for new base image
* Update syslog-ng.conf stats_freq(0); -> stats(freq(0));
* Remove quotes from variable as adjustment for list of consul servers to join

---

3.1

* Version bump for new base image

---

3.0

* Version bump for new base image
* New changelog format

---

2.0.12

* Version bump for rebuild

---

2.0.11

* Fix consul client hcl for new format

---

2.0.10

* Version bump for rebuild to fix missing images on potluck site

---

2.0.9

* Version bump for p3 rebuild

---

2.0.8

* Version bump for latest consul
* Add checklist

---

2.0.7

* Version bump for rebuild

---

2.0.6

* Version bump for new base image
* Adjustments to cook for disabling in nomad and .env.cook
* Remove ssh disable, done in base image

---

2.0.5

* Version bump for FreeBSD-13.1 image

---

2.0.4

* Need additional permissions for exporter user of mysqld_exporter to avoid errors filling up logs

---

2.0.3

* Fix access IP to passed in IP address for mysqld_exporter exporter user

---

2.0.2

* Fix error with mysqld_exporter credentials file preventing mariadb starting on pot image restart

---

2.0.1

* Rebuild for new format flavour image
* Include consul, node_exporter, mysql_exporter

---

1.0.2

* Rebuild for FreeBSD 12_3 and 13 & pot 13

---

1.0.1

* Rebuild for FreeBSD 13 & new packages

---

1.0

* Initial commit
