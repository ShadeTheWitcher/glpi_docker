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

# Clave de cifrado fija: GLPI cifra algunos datos de la base con config/glpicrypt.key.
# Si el archivo cambia en cada arranque, esos datos dejan de poder leerse. La clave (32 bytes en base64)
# va en la variable de entorno GLPI_CRYPT_KEY de Render y se escribe en cada arranque.
KEYFILE="$CONF/glpicrypt.key"
if [ -n "${GLPI_CRYPT_KEY:-}" ]; then
  printf '%s' "$GLPI_CRYPT_KEY" | base64 -d > "$KEYFILE"
  if [ "$(wc -c < "$KEYFILE" | tr -d ' ')" != "32" ]; then
    log "ERROR: GLPI_CRYPT_KEY no es una clave valida (debe ser 32 bytes en base64, generada con: openssl rand -base64 32)"
    rm -f "$KEYFILE"
    exit 1
  fi
  chmod 600 "$KEYFILE"
  log "glpicrypt.key escrita desde GLPI_CRYPT_KEY"
else
  log "AVISO: GLPI_CRYPT_KEY no esta definida; GLPI usara la clave que haya en el contenedor (se pierde al reiniciar)"
fi

exec /opt/glpi/entrypoint.sh "$@"
