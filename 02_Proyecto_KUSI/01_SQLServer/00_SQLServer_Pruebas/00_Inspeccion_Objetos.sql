/* 00 — Inspección: ejecute esto PRIMERO en KUSI_MINIMARKET.
   Muestra firmas reales de sus procedimientos/triggers/funciones y las columnas de
   las tablas clave. Con esto ajuste las líneas marcadas "-- AJUSTAR" de los scripts 02-05. */
USE KUSI_MINIMARKET;
GO
SELECT s.name AS esquema, o.name AS objeto, o.type_desc, p.name AS parametro, TYPE_NAME(p.user_type_id) AS tipo
FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
LEFT JOIN sys.parameters p ON p.object_id=o.object_id
WHERE o.type IN ('P','FN','IF','TF') AND s.name IN ('dbo','audit','calidad')
ORDER BY o.name, p.parameter_id;
SELECT name AS trigger_name, OBJECT_NAME(parent_id) AS tabla, is_disabled FROM sys.triggers WHERE parent_class=1;
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Ventas','DetalleVentas','Productos','LogAuditoria','VentasObservadas','VentasRechazadas')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
