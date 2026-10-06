/* 05 — Rendimiento: consulta crítica sin y con índice (Capítulo 6).
   Consulta crítica: ventas completadas por sucursal y periodo.
   PROCEDIMIENTO: (1) active "Incluir plan de ejecución real" (Ctrl+M) en SSMS. (2) Ejecute el bloque A.
   (3) Ejecute el bloque B. (4) Copie de la pestaña Mensajes: lecturas lógicas y tiempo.
   CAPTURA Figura 9(a) plan sin índice y 9(b) plan con índice; anote los valores en la Tabla 20 del informe. */
USE KUSI_MINIMARKET;
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Ventas_FechaEstadoSucursal' AND object_id=OBJECT_ID('dbo.Ventas'))
    DROP INDEX IX_Ventas_FechaEstadoSucursal ON dbo.Ventas;
DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;   -- solo en entorno de pruebas
GO
/* ---- A. SIN ÍNDICE ---- */
SET STATISTICS IO ON; SET STATISTICS TIME ON;
SELECT id_sucursal, YEAR(fecha_venta) AS anio, MONTH(fecha_venta) AS mes, COUNT(*) AS ventas, SUM(total_venta) AS facturacion
FROM dbo.Ventas
WHERE estado='completada' AND fecha_venta>='2024-01-01' AND fecha_venta<'2025-01-01'
GROUP BY id_sucursal, YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY id_sucursal, anio, mes;
SET STATISTICS IO OFF; SET STATISTICS TIME OFF;
GO
CREATE NONCLUSTERED INDEX IX_Ventas_FechaEstadoSucursal
ON dbo.Ventas(fecha_venta, estado, id_sucursal) INCLUDE (total_venta);
DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;
GO
/* ---- B. CON ÍNDICE (misma consulta, sin cambios) ---- */
SET STATISTICS IO ON; SET STATISTICS TIME ON;
SELECT id_sucursal, YEAR(fecha_venta) AS anio, MONTH(fecha_venta) AS mes, COUNT(*) AS ventas, SUM(total_venta) AS facturacion
FROM dbo.Ventas
WHERE estado='completada' AND fecha_venta>='2024-01-01' AND fecha_venta<'2025-01-01'
GROUP BY id_sucursal, YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY id_sucursal, anio, mes;
SET STATISTICS IO OFF; SET STATISTICS TIME OFF;
