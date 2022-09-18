#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# If we do not find a Nextcloud installation, we install it. If we do find something though,
# we do not install/overwrite anything as we assume that updates/modifications are happening
# from within the Nextcloud installation, we install it. If we do find something though,
# we do not install/overwrite anything as we assume that updates/modifications are happening
# from within Nextcloud.
if [ ! -e /usr/local/www/nextcloud/status.php ]; then
    pkg install -y nextcloud-php80 nextcloud-twofactor_totp-php80 nextcloud-deck-php80 nextcloud-mail-php80 nextcloud-contacts-php80 nextcloud-calendar-php80 nextcloud-end_to_end_encryption-php80
fi
