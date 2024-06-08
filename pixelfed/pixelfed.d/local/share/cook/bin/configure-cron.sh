#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# setup cronjob
echo "* *   *   *   *   root    sudo -u www /usr/local/bin/php /usr/local/www/pixelfed/artisan schedule:run > /dev/null" >> /etc/crontab
