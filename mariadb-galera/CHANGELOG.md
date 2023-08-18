0.0

* Copy mariadb to mariadb-galera and customise for Galera cluster
* Don't create haproxy user on replicas
* Only create mysql_exporter user on primary
* mysqld_exporter runs as user nobody but config file with password has restrictive permissions, fixed
