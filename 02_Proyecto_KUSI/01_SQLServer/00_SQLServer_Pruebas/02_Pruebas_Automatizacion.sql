/* 02 — Pruebas de automatización (Capítulo 5). Base: KUSI_MINIMARKET.
   Cada prueba se ejecuta dentro de una transacción que se REVIERTE al final: no ensucia los datos.
   CAPTURAS: P1 -> Figura 5(a); P2 -> Figura 5(b); P3 -> Figura 6. */
USE KUSI_MINIMARKET;
GO
SET NOCOUNT ON;

/* P1. Trigger de integridad: detalle con cantidad negativa debe ser BLOQUEADO y registrado.
   Esperado: mensaje de error del trigger trg_DetalleVentas_Integridad. */
BEGIN TRY
    BEGIN TRAN;
    INSERT INTO dbo.DetalleVentas(id_detalle,id_venta,id_producto,cantidad,precio_unitario,subtotal) -- AJUSTAR columnas/identity
    VALUES (9999991, 100, 1, -5, 2.50, -12.50);
    COMMIT; PRINT 'ERROR DE PRUEBA: el trigger NO bloqueó la inserción';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK;
    SELECT 'P1 BLOQUEADO POR TRIGGER' AS resultado, ERROR_NUMBER() AS nro, ERROR_MESSAGE() AS mensaje;
END CATCH;

/* P2. El intento quedó en el log de auditoría (el log debe escribirse FUERA de la transacción revertida,
   como lo hace el trigger de la entrega parcial; si su trigger revierte también el log, indíquelo en el informe). */
SELECT TOP (10) * FROM audit.LogAuditoria ORDER BY 1 DESC;

/* P3. Validación en dos etapas: una venta sin detalle NO pasa a 'completada' (Q07).
   Se usan las ventas problemáticas conocidas: 61575..61578 (total 0 y sin detalle). */
SELECT v.id_venta, v.estado, v.total_venta,
       (SELECT COUNT(*) FROM dbo.DetalleVentas d WHERE d.id_venta=v.id_venta) AS detalles
FROM dbo.Ventas v WHERE v.id_venta IN (100,500,61575,61576,61577,61578);
-- EXEC dbo.sp_ValidarVenta @id_venta = 61575;   -- AJUSTAR nombre de parámetro; esperado: error controlado (THROW) y ROLLBACK

/* P4. Funciones reutilizables (RF05): productos a reabastecer (Q08 = 6 productos). */
SELECT * FROM dbo.fn_ProductosParaReabastecer();   -- AJUSTAR si recibe parámetros
SELECT COUNT(*) AS productos_a_reabastecer FROM dbo.fn_ProductosParaReabastecer();

/* P5. Auditoría de UPDATE sobre ventas (trg_Ventas_Auditoria): cambio reversible. */
BEGIN TRAN;
    UPDATE dbo.Ventas SET estado = estado WHERE id_venta = 100;   -- AJUSTAR: un UPDATE real que dispare el trigger
    SELECT TOP (3) * FROM audit.LogAuditoria ORDER BY 1 DESC;
ROLLBACK;
