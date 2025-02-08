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
chown -R www:www "/mnt/$SITENAME"

# add changed files
cd "/mnt/${SITENAME}" || exit 1

# shellcheck disable=SC2035
/usr/local/bin/git add -v * || true

# commit and push
#/usr/local/bin/git commit -m "Changed templates via cook script"

# start hugo
# test server
# hugo server -b http://${IP}:1313 --bind ${IP} -D
chown -R www:www "/mnt/$SITENAME"

# run hugo
/usr/local/bin/hugo || true

# create sample pages
# we need this to create the blog and microblog directories
if [ ! -f "/mnt/${SITENAME}/blog/sample-blog-post.md" ]; then
    /usr/local/bin/hugo new blog/sample-blog-post.md || true
fi
if [ ! -f "/mnt/${SITENAME}/micro/sample-microblog-post.md" ]; then
    /usr/local/bin/hugo new micro/sample-microblog-post.md || true
fi

# check ownership again
chown -R www:www "/mnt/$SITENAME"

# set permissions again so remote user can write files from other image
# there might be another way to do this with more security
chmod 777 "/mnt/$SITENAME"
chmod 777 "/mnt/$SITENAME/$CUSTOMDIR"
chmod 777 "/mnt/$SITENAME/content"
chmod 777 "/mnt/$SITENAME/content/blog"
chmod 666 "/mnt/$SITENAME/content/blog/*.md" || true
chmod 777 "/mnt/$SITENAME/content/micro"
chmod 666 "/mnt/$SITENAME/content/micro/*.md" || true
chmod 777 "/mnt/$SITENAME/static"
