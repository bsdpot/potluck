#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

cp -f "$TEMPLATEPATH/custom_theme_default_list.html" \
  "/mnt/$SITENAME/themes/kiss-em/layouts/_default/list.html"

cp -f "$TEMPLATEPATH/custom_theme_blog_list.html" \
  "/mnt/$SITENAME/themes/kiss-em/layouts/blog/list.html"

cp -f "$TEMPLATEPATH/custom_theme_partial_article.html" \
  "/mnt/$SITENAME/themes/kiss-em/layouts/partials/article.html"

# ERROR deprecated: .Site.RSSLink was deprecated in Hugo v0.114.0
# and will be removed in Hugo 0.134.0. Use the Output Format's
# Permalink method instead, e.g. .OutputFormats.Get "RSS".Permalink
# removed the problematic section with if .Site.Params.rss.enable
cp -f "$TEMPLATEPATH/custom_theme_partial_header.html" \
  "/mnt/$SITENAME/themes/kiss-em/layouts/partials/header.html"

cp -f "$TEMPLATEPATH/custom_theme_partial_footer.html" \
  "/mnt/$SITENAME/themes/kiss-em/layouts/partials/footer.html"

cp -f "$TEMPLATEPATH/custom_theme_taxonomy_tag.html" \
  "/mnt/$SITENAME/themes/kiss-em/layouts/taxonomy/tag.html"
