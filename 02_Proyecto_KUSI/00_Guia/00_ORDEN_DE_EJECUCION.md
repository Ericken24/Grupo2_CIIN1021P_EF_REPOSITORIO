# Orden de ejecución — KUSI MINIMARKET

Este proyecto se construye de forma progresiva. La idea es que cada bloque deje un resultado verificable antes de pasar al siguiente.

## Bloque A — SQL Server operacional
1. `01_SQLServer/01_Creacion_BaseDatos_Esquemas.sql`
2. `01_SQLServer/02_Creacion_Tablas_Staging.sql`
3. `01_SQLServer/03_Carga_Staging_BulkInsert.sql` — ajustar la ruta de los CSV.
4. `01_SQLServer/04_Auditoria_Calidad_Staging.sql`
5. `01_SQLServer/05_Creacion_Tablas_Operacionales.sql`
6. `01_SQLServer/06_Carga_Operacional_Desde_Staging.sql`
7. `01_SQLServer/07_Procedimientos_Almacenados.sql`
8. `01_SQLServer/08_Triggers_Auditoria_Integridad.sql`
9. `01_SQLServer/09_Funciones.sql`
10. `01_SQLServer/10_Roles_Seguridad_Permisos.sql`
11. `01_SQLServer/11_Politica_Backup_Restore.sql` — ajustar carpeta de backups.
12. `01_SQLServer/12_Indices_PlanesEjecucion.sql`
13. `01_SQLServer/13_Pruebas_Evidencias_EP.sql`

## Bloque B — MongoDB
1. `02_MongoDB/01_Creacion_Coleccion_Promociones.js`
2. `02_MongoDB/02_Carga_Real_Promociones.js`
3. `02_MongoDB/03_Operaciones_CRUD.js`
4. `02_MongoDB/04_Comparativa_SQL_vs_NoSQL.md`

## Bloque C — Data Warehouse y ETL
1. `03_DataWarehouse/01_Creacion_DW_Dimensiones_Hechos.sql`
2. `03_DataWarehouse/02_Diagrama_Modelo_Estrella.md`
3. `03_DataWarehouse/03_ETL_Python_CargaDW.py`
4. `03_DataWarehouse/04_Justificacion_Kimball_vs_Inmon.md`

## Bloque D — Documentación y evidencias
- `04_Documentacion/01_Relevamiento_Supuestos_Requisitos.md`
- `04_Documentacion/02_Cronograma_EP.md`
- `04_Documentacion/03_Matriz_Riesgos_Articulacion.md`
- `04_Documentacion/04_Matriz_Evidencias_EP.md`
- `05_Evidencias/README.md`

> No se debe afirmar que una prueba fue ejecutada hasta guardar su resultado real. Los valores de rendimiento, restore y tiempos deben tomarse directamente de SQL Server/Python/MongoDB durante la ejecución.
