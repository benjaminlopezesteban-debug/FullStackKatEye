# KatEye-DB

Base de datos MySQL 8.4 del entorno unificado. **Flyway es el dueño del esquema**: las migraciones viven en `KatEye-Back/katEye/src/main/resources/db/migration/` y se aplican al arrancar el backend.

La carpeta `init/` es opcional y no debe usarse para crear tablas ni datos que ya cubre Flyway. El volumen `kateye_mysqldata` conserva los datos entre reinicios; `docker compose down -v` lo elimina.
