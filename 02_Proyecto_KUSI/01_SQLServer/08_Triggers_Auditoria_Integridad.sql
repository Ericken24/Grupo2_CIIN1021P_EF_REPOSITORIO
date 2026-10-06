/* ================================================================
   KUSI MINIMARKET — SCRIPT 08
   Triggers de auditoría, integridad y alerta operativa
   ================================================================

   Los triggers cubren tres situaciones distintas:
   1) Auditoría automática de cambios sobre Ventas.
   2) Integridad de DetalleVentas: un intento inválido se registra y
      no se inserta.
   3) Alerta de stock: cuando el inventario llega al mínimo se deja
      una señal para el área de compras.
*/
USE KUSI_MINIMARKET;
GO

/* 1. Auditoría DML. Se trabaja de forma set-based para que también
      funcione correctamente cuando una sentencia modifica varias filas. */
CREATE OR ALTER TRIGGER dbo.trg_Ventas_Auditoria
ON dbo.Ventas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
    SELECT 'Ventas','INSERT',CONVERT(NVARCHAR(100),i.id_venta),'Alta registrada automaticamente por trigger.'
    FROM inserted i LEFT JOIN deleted d ON d.id_venta=i.id_venta WHERE d.id_venta IS NULL;

    INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
    SELECT 'Ventas','UPDATE',CONVERT(NVARCHAR(100),i.id_venta),CONCAT('Cambio auditado. Estado anterior=',COALESCE(d.estado,'NULL'),' estado nuevo=',i.estado)
    FROM inserted i INNER JOIN deleted d ON d.id_venta=i.id_venta;

    INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
    SELECT 'Ventas','DELETE',CONVERT(NVARCHAR(100),d.id_venta),'Baja registrada automaticamente por trigger.'
    FROM deleted d LEFT JOIN inserted i ON i.id_venta=d.id_venta WHERE i.id_venta IS NULL;
END;
GO

/* 2. Integridad de detalle. Al ser INSTEAD OF INSERT, primero podemos
      revisar y registrar el intento; solo las filas válidas se insertan.
      Las restricciones CHECK siguen actuando como segunda barrera. */
CREATE OR ALTER TRIGGER dbo.trg_DetalleVentas_Integridad
ON dbo.DetalleVentas
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
    SELECT 'DetalleVentas','ERROR',CONVERT(NVARCHAR(100),id_detalle),
           CONCAT('Intento rechazado: cantidad=',cantidad,', precio=',precio_unitario,', subtotal=',subtotal)
    FROM inserted
    WHERE cantidad<=0 OR precio_unitario<=0 OR subtotal<=0
       OR ABS(subtotal-(cantidad*precio_unitario))>0.01;

    IF EXISTS (SELECT 1 FROM inserted WHERE cantidad<=0 OR precio_unitario<=0 OR subtotal<=0 OR ABS(subtotal-(cantidad*precio_unitario))>0.01)
        THROW 51050,'Detalle invalido: cantidad, precio y subtotal deben ser positivos y subtotal=cantidad*precio.',1;

    INSERT INTO dbo.DetalleVentas(id_detalle,id_venta,id_producto,cantidad,precio_unitario,subtotal)
    SELECT id_detalle,id_venta,id_producto,cantidad,precio_unitario,subtotal FROM inserted;
END;
GO

/* 3. Alerta de stock. Solo registra el momento en que un producto
      cruza hacia el nivel mínimo o inferior; evita generar una alerta
      idéntica en cada UPDATE que no cambie la situación. */
CREATE OR ALTER TRIGGER dbo.trg_Productos_StockBajo
ON dbo.Productos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(stock)
    BEGIN
        INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
        SELECT 'Productos','ALERTA_STOCK',CONVERT(NVARCHAR(100),i.id_producto),
               CONCAT('Stock=',i.stock,'; minimo=',i.stock_minimo)
        FROM inserted i INNER JOIN deleted d ON d.id_producto=i.id_producto
        WHERE i.stock<=i.stock_minimo AND d.stock>i.stock_minimo;
    END
END;
GO
