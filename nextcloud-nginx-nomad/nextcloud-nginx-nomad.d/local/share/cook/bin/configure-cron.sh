#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# setup nextcloud cronjob
echo "*/15 * * * *  www  /usr/local/bin/php -f /usr/local/www/nextcloud/cron.php" >> /etc/crontab
