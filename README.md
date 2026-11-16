# GLPI 11.0.4 en Render (base de datos externa)

Imagen basada en `glpi/glpi:11.0.4` que arma `config_db.php` desde variables de entorno.
No contiene secretos: la conexion a la base va en las variables del servicio de Render.

Variables obligatorias (Render > Environment): `GLPI_DB_HOST`, `GLPI_DB_PORT`, `GLPI_DB_NAME`, `GLPI_DB_USER`, `GLPI_DB_PASSWORD`.
Si Render no detecta el puerto, agregar `PORT=80`.

Estas dos ya vienen activadas en el Dockerfile y evitan que se instale o actualice sola sobre la base: `GLPI_SKIP_AUTOINSTALL=true`, `GLPI_SKIP_AUTOUPDATE=true`.
