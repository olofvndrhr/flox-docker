#!/bin/sh
set -eu

UID=${UID:-1000}
GID=${GID:-1000}
FLOX_DB_INIT=${FLOX_DB_INIT:-false}
FLOX_DB_CONNECTION=${FLOX_DB_CONNECTION:-sqlite}
FLOX_DB_NAME=${FLOX_DB_NAME:-/var/www/flox/backend/database/database.sqlite}
FLOX_DB_USER=${FLOX_DB_USER:-}
FLOX_DB_PASS=${FLOX_DB_PASS:-}
FLOX_DB_HOST=${FLOX_DB_HOST:-localhost}
FLOX_DB_PORT=${FLOX_DB_PORT:-3306}
FLOX_ADMIN_USER=${FLOX_ADMIN_USER:-admin}
FLOX_ADMIN_PASS=${FLOX_ADMIN_PASS:-admin}
FLOX_APP_URL=${FLOX_APP_URL:-http://localhost}
FLOX_APP_ENV=${FLOX_APP_ENV:-local}
FLOX_APP_DEBUG=${FLOX_APP_DEBUG:-false}
FLOX_CLIENT_URI=${FLOX_CLIENT_URI:-/}
FLOX_TIMEZONE=${FLOX_TIMEZONE:-UTC}
FLOX_DAILY_REMINDER_TIME=${FLOX_DAILY_REMINDER_TIME:-10:00}
FLOX_WEEKLY_REMINDER_TIME=${FLOX_WEEKLY_REMINDER_TIME:-20:00}
FLOX_MAIL_DRIVER=${FLOX_MAIL_DRIVER:-}
FLOX_MAIL_HOST=${FLOX_MAIL_HOST:-}
FLOX_MAIL_PORT=${FLOX_MAIL_PORT:-}
FLOX_MAIL_USERNAME=${FLOX_MAIL_USERNAME:-}
FLOX_MAIL_PASSWORD=${FLOX_MAIL_PASSWORD:-}
FLOX_MAIL_ENCRYPTION=${FLOX_MAIL_ENCRYPTION:-}
TMDB_API_KEY=${TMDB_API_KEY}


usermod -o -u "$UID" foo
groupmod -o -g "$GID" foo

rsync -rlD --delete \
           --exclude /backend/.env \
           --exclude /backend/database/database.sqlite \
           --exclude /backend/database/database.sqlite-journal \
           --exclude /public/assets/backdrop/ \
           --exclude /public/assets/poster/ \
           --exclude /public/exports/ \
           /usr/share/flox/ /var/www/flox

cd backend

if [ "$FLOX_DB_CONNECTION" = "sqlite" ]; then
    touch /var/www/flox/backend/database/database.sqlite
    php artisan flox:init --no-interaction $FLOX_DB_NAME
else
    php artisan flox:init --no-interaction $FLOX_DB_NAME $FLOX_DB_USER $FLOX_DB_PASS $FLOX_DB_HOST $FLOX_DB_PORT
fi

sed -ri -e 's,^DB_CONNECTION=.*,DB_CONNECTION='"${FLOX_DB_CONNECTION}"',g' .env
sed -ri -e 's,^TMDB_API_KEY=.*,TMDB_API_KEY='"${TMDB_API_KEY}"',g' .env
sed -ri -e 's,^APP_URL=.*,APP_URL='"${FLOX_APP_URL}"',g' .env
sed -ri -e 's,^CLIENT_URI=.*,CLIENT_URI='"${FLOX_CLIENT_URI}"',g' .env
sed -ri -e 's,^APP_DEBUG=.*,APP_DEBUG='"${FLOX_APP_DEBUG}"',g' .env
sed -ri -e 's,^TIMEZONE=.*,TIMEZONE='"${FLOX_TIMEZONE}"',g' .env
sed -ri -e 's,^DAILY_REMINDER_TIME=.*,DAILY_REMINDER_TIME='"${FLOX_DAILY_REMINDER_TIME}"',g' .env
sed -ri -e 's,^WEEKLY_REMINDER_TIME=.*,WEEKLY_REMINDER_TIME='"${FLOX_WEEKLY_REMINDER_TIME}"',g' .env
sed -ri -e 's,^APP_ENV=.*,APP_ENV=local,g' .env
sed -ri -e 's,^MAIL_DRIVER=.*,MAIL_DRIVER='"${FLOX_MAIL_DRIVER}"',g' .env
sed -ri -e 's,^MAIL_HOST=.*,MAIL_HOST='"${FLOX_MAIL_HOST}"',g' .env
sed -ri -e 's,^MAIL_PORT=.*,MAIL_PORT='"${FLOX_MAIL_PORT}"',g' .env
sed -ri -e 's,^MAIL_USERNAME=.*,MAIL_USERNAME='"${FLOX_MAIL_USERNAME}"',g' .env
sed -ri -e 's,^MAIL_PASSWORD=.*,MAIL_PASSWORD='"${FLOX_MAIL_PASSWORD}"',g' .env
sed -ri -e 's,^MAIL_ENCRYPTION=.*,MAIL_ENCRYPTION='"${FLOX_MAIL_ENCRYPTION}"',g' .env

if [ "$FLOX_DB_INIT" = "true" ]; then
    php artisan flox:db --no-interaction $FLOX_ADMIN_USER $FLOX_ADMIN_PASS
else
    php artisan migrate
fi

sed -i "s!^APP_ENV=.*!APP_ENV=$FLOX_APP_ENV!g" .env

chown foo /proc/self/fd/1 /proc/self/fd/2
chown -R foo:foo /var/www/flox \
                 /var/log/supervisord \
                 /var/run/supervisord \
                 /var/spool/cron/crontabs

service nginx start

exec gosu foo "$@"
