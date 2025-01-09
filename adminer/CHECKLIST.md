# On flavour version change

`adminer/adminer.ini` update:
* `version = "{0.1}"`

# On adminer version change

In `adminer/adminer.d/local/share/cook/bin/configure-adminer.sh` update:
* `curl -L -o /usr/local/www/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v{4.8.1}/editor-{4.8.1}.php`
* `curl -L -o /usr/local/www/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v{4.8.1}/adminer-{4.8.1}.php`

# On php version change

In `adminer/adminer.sh` update:
```sh
pkg install -y php83
pkg install -y php83-mbstring
pkg install -y php83-zlib
pkg install -y php83-curl
pkg install -y php83-gd
pkg install -y php83-extensions
pkg install -y php83-mysqli
pkg install -y php83-odbc
pkg install -y php83-pgsql
pkg install -y php83-pdo_sqlite
```

Also update the PHP socket in
* `adminer.d/local/share/cook/templates/nginx.conf.in`
* `adminer.d/local/share/cook/templates/www.conf.in`
