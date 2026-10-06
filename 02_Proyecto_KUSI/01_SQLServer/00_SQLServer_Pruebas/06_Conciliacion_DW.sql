/* 06 — Conciliación OLTP -> DW (Capítulo 8). Ejecutar después del ETL.
   CAPTURA Figura 13: resultado de los tres bloques. */
USE KUSI_DW;
GO
SELECT 'Ventas distintas en el hecho' AS control, COUNT(DISTINCT IdVentaOrigen) AS valor FROM dw.FactVentas
UNION ALL SELECT 'Filas de FactVentas (grano producto-venta)', COUNT(*) FROM dw.FactVentas
UNION ALL SELECT 'Filas con cliente anonimo (KeyCliente=0)', COUNT(*) FROM dw.FactVentas WHERE KeyCliente=0
UNION ALL SELECT 'Ventas anonimas distintas', COUNT(DISTINCT IdVentaOrigen) FROM dw.FactVentas WHERE KeyCliente=0;
-- Esperado: ventas distintas = 179994 (180000 - 2 fuera de periodo - 4 total cero/sin detalle)
SELECT 'Fecha minima/maxima' AS control, CONVERT(VARCHAR(10),MIN(f.Fecha))+' a '+CONVERT(VARCHAR(10),MAX(f.Fecha)) AS valor
FROM dw.FactVentas h JOIN dw.DimFecha f ON f.KeyFecha=h.KeyFecha;
-- Esperado: dentro de 2023-01-01 .. 2025-08-31
SELECT TOP 20 id_log, fecha_ejecucion, origen, filas_leidas, filas_aceptadas, filas_rechazadas, motivo_rechazo
FROM dw.LogETL ORDER BY id_log;
-- Verificación cruzada contra el OLTP (si ambas bases están en el mismo servidor):
SELECT (SELECT COUNT(DISTINCT IdVentaOrigen) FROM KUSI_DW.dw.FactVentas) AS ventas_dw,
       (SELECT COUNT(*) FROM KUSI_MINIMARKET.dbo.Ventas WHERE estado='completada'
          AND fecha_venta>='2023-01-01' AND fecha_venta<'2025-09-01') AS ventas_oltp_periodo;
