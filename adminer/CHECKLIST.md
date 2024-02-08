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
pkg install -y php82
pkg install -y php82-mbstring
pkg install -y php82-zlib
pkg install -y php82-curl
pkg install -y php82-gd
pkg install -y php82-extensions
pkg install -y php82-mysqli
pkg install -y php82-odbc
pkg install -y php82-pgsql
pkg install -y php82-pdo_sqlite
```
