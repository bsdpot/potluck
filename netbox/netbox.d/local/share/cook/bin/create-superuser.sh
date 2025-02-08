#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH="/usr/local/bin:$PATH"

# docker-compose version uses different approach which may be more useful
# to avoid error condition in output. Not in use until scripted token 
# generation is possible.
#
# https://github.com/netbox-community/netbox-docker/blob/release/docker/docker-entrypoint.sh
#   ./manage.py shell --interface python <<END
# from users.models import Token, User
# if not User.objects.filter(username='${SUPERUSER_NAME}'):
#     u = User.objects.create_superuser('${SUPERUSER_NAME}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
#     Token.objects.create(user=u, key='${SUPERUSER_API_TOKEN}')
# END
#
# Command below has output as follows:
# Success on first create:
#  Superuser created successfully.
# Failure on repeat:
#  CommandError: Error: That username is already taken.

cd /usr/local/share/netbox || exit 1

DJANGO_SUPERUSER_PASSWORD="$ADMINPASSWORD" /usr/local/bin/python3.11 manage.py createsuperuser --no-input --username "$ADMINNAME" --email "$ADMINEMAIL" || true
