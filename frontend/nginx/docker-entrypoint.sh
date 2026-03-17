#!/bin/sh
# docker-entrypoint.sh - Generates nginx config from template at container start
#
# Replaces ${ORIGIN_VERIFY_SECRET} in the template with the actual secret value.
# This allows the origin verify header to be passed as an environment variable
# without baking secrets into the Docker image.
#
# In local dev (no ORIGIN_VERIFY_SECRET set), the variable is empty and
# the origin check is skipped -- all requests pass through.

# Only substitute our custom variable, leave nginx variables ($uri etc.) untouched
envsubst '${ORIGIN_VERIFY_SECRET}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Start nginx in foreground
exec nginx -g 'daemon off;'
