#!/bin/sh
# Genera config/config_db.php a partir de GLPI_DB_* y sigue con el arranque normal de la imagen oficial.
# No toca la base de datos: solo escribe el archivo de conexion.
set -eu

log() { echo "[render-entrypoint] $*"; }

for v in GLPI_DB_HOST GLPI_DB_PORT GLPI_DB_NAME GLPI_DB_USER GLPI_DB_PASSWORD; do
  eval "val=\${$v:-}"
  if [ -z "$val" ]; then
    log "ERROR: falta la variable de entorno $v"
    exit 1
  fi
done

CONF="${GLPI_CONFIG_DIR:-/var/glpi/config}"

# Mismas carpetas que crea el arranque oficial (la consola las necesita antes de que corra)
for d in config files marketplace logs files/_cache files/_cron files/_dumps files/_graphs files/_locales \
         files/_lock files/_pictures files/_plugins files/_rss files/_sessions files/_tmp files/_uploads \
         files/_inventories; do
  mkdir -p "/var/glpi/$d"
done

if [ ! -f "$CONF/config_db.php" ]; then
  log "Generando $CONF/config_db.php (host $GLPI_DB_HOST:$GLPI_DB_PORT, base $GLPI_DB_NAME)"
  php /var/www/glpi/bin/console database:configure \
    --no-interaction --reconfigure \
    --db-host="$GLPI_DB_HOST" --db-port="$GLPI_DB_PORT" \
    --db-name="$GLPI_DB_NAME" --db-user="$GLPI_DB_USER" --db-password="$GLPI_DB_PASSWORD"
else
  log "$CONF/config_db.php ya existe, no se regenera"
fi

exec /opt/glpi/entrypoint.sh "$@"
