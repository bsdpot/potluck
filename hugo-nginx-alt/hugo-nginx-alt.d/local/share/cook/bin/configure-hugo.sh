#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# final perms check
chown -R www:www "/var/db/$SITENAME"

# add changed files
cd "/var/db/${SITENAME}" || exit 1

# shellcheck disable=SC2035
/usr/local/bin/git add -v * || true

# commit and push
#/usr/local/bin/git commit -m "Changed templates via cook script"

# start hugo
# test server
# hugo server -b http://${IP}:1313 --bind ${IP} -D

# set www permissions on sitefolder
chown -R www:www "/var/db/$SITENAME"

# run hugo
/usr/local/bin/hugo || true

# create sample pages
# we need this to create the blog and microblog directories
if [ ! -f "/var/db/${SITENAME}/blog/sample-blog-post.md" ]; then
    /usr/local/bin/hugo new blog/sample-blog-post.md || true
fi
if [ ! -f "/var/db/${SITENAME}/micro/sample-microblog-post.md" ]; then
    /usr/local/bin/hugo new micro/sample-microblog-post.md || true
fi

# check ownership again
chown -R www:www "/var/db/$SITENAME"

# to-do remove this, not using remote image to write to this one
# set permissions again so remote user can write files from other image
# there might be another way to do this with more security
#chmod 777 "/var/db/$SITENAME"
#chmod 777 "/var/db/$SITENAME/content"
#chmod 777 "/var/db/$SITENAME/content/blog"
#chmod 666 "/var/db/$SITENAME/content/blog/*.md" || true
#chmod 777 "/var/db/$SITENAME/content/micro"
#chmod 666 "/var/db/$SITENAME/content/micro/*.md" || true
#chmod 777 "/var/db/$SITENAME/layouts/"
#chmod 777 "/var/db/$SITENAME/layouts/partials"
#chmod 777 "/var/db/$SITENAME/layouts/partials/head"
#chmod 777 "/var/db/$SITENAME/layouts/partials/header"
#chmod 777 "/var/db/$SITENAME/static"

if [ -d "/var/db/$SITENAME/$CUSTOMDIR" ]; then
	chmod 777 "/var/db/$SITENAME/$CUSTOMDIR"
fi
