#!/bin/sh
set -e

mkdir -p /app/static /app/media
chmod -R 755 /app/static /app/media

python manage.py collectstatic --noinput

exec "$@"