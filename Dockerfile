# GLPI 11.0.4 para Render: genera config_db.php desde las variables de entorno en cada arranque.
# Sin esto, la imagen oficial pierde /var/glpi/config al reiniciarse (no hay disco persistente),
# cree que no esta instalada y trata de instalarse sobre la base existente.
FROM glpi/glpi:11.0.4

USER root
COPY render-entrypoint.sh /opt/render-entrypoint.sh
# sed por si el archivo llego con saltos de linea de Windows (CRLF)
RUN sed -i 's/\r$//' /opt/render-entrypoint.sh && chmod 755 /opt/render-entrypoint.sh

# Render corre el contenedor como www-data (no root): supervisor y Apache necesitan poder escribir
# sus logs, pid y socket. Se crean y se les da permiso a esas rutas.
RUN mkdir -p /var/log/supervisor /var/log/apache2 /var/run/apache2 /var/lock/apache2 \
 && chown -R www-data:www-data /var/log/supervisor /var/log/apache2 /var/run/apache2 /var/lock/apache2 \
 && chmod 1777 /run

# Nunca instalar ni actualizar la base automaticamente (la base ya esta instalada)
ENV GLPI_SKIP_AUTOINSTALL=true \
    GLPI_SKIP_AUTOUPDATE=true

USER www-data

# Al cambiar ENTRYPOINT, Docker descarta el CMD heredado: se vuelve a declarar el mismo de la imagen oficial
ENTRYPOINT ["/opt/render-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
