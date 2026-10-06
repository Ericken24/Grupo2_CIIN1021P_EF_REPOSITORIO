/* ================================================================
   KUSI MINIMARKET — SCRIPT 12
   Plan de ejecución y medición antes/después
   ================================================================

   La consulta elegida representa un patrón frecuente de BI:
   ventas completadas agrupadas por sucursal y filtradas por fecha.
   Primero se mide sin el índice y después con el índice.

   La evidencia debe contener: Actual Execution Plan + STATISTICS IO
   + STATISTICS TIME de ambos escenarios.
*/
USE KUSI_MINIMARKET;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

/* MEDICIÓN A — SIN índice IX_Ventas_FechaSucursalEstado.
   Ejecutar con Ctrl+M para mostrar el plan real. */
SELECT id_sucursal,COUNT(*) AS numero_ventas,SUM(total_venta) AS total_facturado
FROM dbo.Ventas
WHERE fecha_venta>='2024-01-01' AND fecha_venta<'2024-04-01'
  AND estado='completada'
GROUP BY id_sucursal
ORDER BY total_facturado DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* Crear índice alineado con los predicados de fecha/estado y la
   agrupación por sucursal. INCLUDE evita lecturas adicionales de total. */
CREATE INDEX IX_Ventas_FechaEstadoSucursal
ON dbo.Ventas(fecha_venta,estado,id_sucursal)
INCLUDE(total_venta);
GO

CREATE INDEX IX_DetalleVentas_VentaProducto
ON dbo.DetalleVentas(id_venta,id_producto)
INCLUDE(cantidad,precio_unitario,subtotal);
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

/* MEDICIÓN B — MISMA consulta, después del índice. */
SELECT id_sucursal,COUNT(*) AS numero_ventas,SUM(total_venta) AS total_facturado
FROM dbo.Ventas
WHERE fecha_venta>='2024-01-01' AND fecha_venta<'2024-04-01'
  AND estado='completada'
GROUP BY id_sucursal
ORDER BY total_facturado DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

SELECT t.name AS tabla,i.name AS indice,i.type_desc
FROM sys.indexes i INNER JOIN sys.tables t ON t.object_id=i.object_id
WHERE i.name IN('IX_Ventas_FechaEstadoSucursal','IX_DetalleVentas_VentaProducto');
GO
