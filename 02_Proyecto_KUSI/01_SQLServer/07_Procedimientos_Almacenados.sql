/* ================================================================
   KUSI MINIMARKET — SCRIPT 07
   Procedimientos almacenados
   ================================================================

   Además de cumplir el mínimo solicitado, se incorporan procesos
   que tienen sentido para el negocio: registrar una venta, agregar
   su detalle, validar la consistencia, consultar oportunidades de
   expansión y medir el comportamiento de una categoría promocionada.

   Los procedimientos que modifican datos usan TRY/CATCH y
   transacciones. Las consultas analíticas registran su ejecución en
   la bitácora para dejar trazabilidad de la operación.
*/
USE KUSI_MINIMARKET;
GO

/* 1. Registro de cabecera de venta.
   SAVE TRANSACTION permite marcar un punto de control dentro de la
   transacción. Ante una validación de negocio fallida se vuelve a ese
   punto; ante un error inesperado se revierte toda la operación. */
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarVenta
    @id_venta INT,
    @id_cliente INT = NULL,
    @id_empleado INT,
    @id_sucursal INT,
    @id_metodo_pago INT,
    @fecha_venta DATETIME2(0),
    @subtotal DECIMAL(12,2),
    @igv DECIMAL(12,2),
    @total_venta DECIMAL(12,2),
    @numero_comprobante VARCHAR(50) = NULL,
    @tipo_comprobante VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        SAVE TRANSACTION AntesDeRegistrarVenta;

        IF @total_venta <= 0
           OR @subtotal < 0
           OR @igv < 0
           OR ABS(@total_venta - (@subtotal + @igv)) > 0.01
           OR ABS(@igv - (@subtotal * 0.18)) > 0.02
            THROW 51001, 'Venta invalida: subtotal, IGV y total no cumplen las reglas de negocio.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Ventas WHERE id_venta=@id_venta)
            THROW 51002, 'Ya existe una venta con el id indicado.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Empleados WHERE id_empleado=@id_empleado AND activo=1)
            THROW 51003, 'El empleado no existe o no esta activo.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Sucursales WHERE id_sucursal=@id_sucursal AND vende=1)
            THROW 51004, 'La sucursal no existe o no esta habilitada para ventas.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.MetodosPago WHERE id_metodo_pago=@id_metodo_pago AND activo=1)
            THROW 51005, 'El metodo de pago no existe o no esta activo.', 1;

        IF @id_cliente IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.Clientes WHERE id_cliente=@id_cliente AND activo=1)
            THROW 51006, 'El cliente indicado no existe o no esta activo.', 1;

        INSERT INTO dbo.Ventas(id_venta,id_cliente,id_empleado,id_sucursal,id_metodo_pago,fecha_venta,subtotal,igv,total_venta,numero_comprobante,tipo_comprobante,estado)
        VALUES(@id_venta,@id_cliente,@id_empleado,@id_sucursal,@id_metodo_pago,@fecha_venta,@subtotal,@igv,@total_venta,@numero_comprobante,@tipo_comprobante,'pendiente');

        INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
        VALUES('Ventas','INSERT',CONVERT(NVARCHAR(100),@id_venta),'Venta registrada como pendiente de validacion.');

        COMMIT TRANSACTION;
        SELECT 'OK' AS resultado, @id_venta AS id_venta, 'pendiente' AS estado;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        BEGIN TRY
            INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
            VALUES('Ventas','ERROR',CONVERT(NVARCHAR(100),@id_venta),ERROR_MESSAGE());
        END TRY BEGIN CATCH END CATCH;
        THROW;
    END CATCH
END;
GO

/* 2. Registro del detalle. Se controla la operación completa para que
   una línea inválida nunca llegue a la tabla. */
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarDetalleVenta
    @id_detalle INT,
    @id_venta INT,
    @id_producto INT,
    @cantidad INT,
    @precio_unitario DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @subtotal DECIMAL(12,2) = ROUND(@cantidad*@precio_unitario,2);
    BEGIN TRY
        BEGIN TRANSACTION;
        SAVE TRANSACTION AntesDeRegistrarDetalle;

        IF @cantidad<=0 OR @precio_unitario<=0
            THROW 51010,'Cantidad y precio unitario deben ser mayores que cero.',1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Ventas WHERE id_venta=@id_venta)
            THROW 51011,'La venta indicada no existe.',1;
        IF NOT EXISTS (SELECT 1 FROM dbo.Productos WHERE id_producto=@id_producto AND activo=1)
            THROW 51012,'El producto indicado no existe o no esta activo.',1;
        IF EXISTS (SELECT 1 FROM dbo.DetalleVentas WHERE id_detalle=@id_detalle)
            THROW 51013,'Ya existe un detalle con el id indicado.',1;

        INSERT INTO dbo.DetalleVentas(id_detalle,id_venta,id_producto,cantidad,precio_unitario,subtotal)
        VALUES(@id_detalle,@id_venta,@id_producto,@cantidad,@precio_unitario,@subtotal);

        INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
        VALUES('DetalleVentas','INSERT',CONVERT(NVARCHAR(100),@id_detalle),CONCAT('Detalle agregado a venta ',@id_venta,'.'));

        COMMIT TRANSACTION;
        SELECT 'OK' AS resultado,@id_detalle AS id_detalle,@subtotal AS subtotal;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        BEGIN TRY
            INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
            VALUES('DetalleVentas','ERROR',CONVERT(NVARCHAR(100),@id_detalle),ERROR_MESSAGE());
        END TRY BEGIN CATCH END CATCH;
        THROW;
    END CATCH
END;
GO

/* 3. Validación posterior de una venta.
   La venta pasa a completada solamente cuando el detalle existe,
   suma el subtotal de la cabecera y los impuestos cuadran. */
CREATE OR ALTER PROCEDURE dbo.sp_ValidarVenta
    @id_venta INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @subtotal DECIMAL(12,2),@igv DECIMAL(12,2),@total DECIMAL(12,2),@suma_detalle DECIMAL(12,2),@estado VARCHAR(20);

        SELECT @subtotal=subtotal,@igv=igv,@total=total_venta,@estado=estado
        FROM dbo.Ventas WHERE id_venta=@id_venta;
        IF @estado IS NULL THROW 51020,'La venta no existe.',1;

        SELECT @suma_detalle=COALESCE(SUM(subtotal),0)
        FROM dbo.DetalleVentas WHERE id_venta=@id_venta;

        IF @total<=0 OR ABS(@total-(@subtotal+@igv))>0.01 OR ABS(@igv-(@subtotal*0.18))>0.02
           OR @suma_detalle<=0 OR ABS(@subtotal-@suma_detalle)>0.01
        BEGIN
            UPDATE dbo.Ventas SET estado='rechazada' WHERE id_venta=@id_venta;
            INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
            VALUES('Ventas','VALIDACION',CONVERT(NVARCHAR(100),@id_venta),'Venta rechazada: cabecera y detalle no cumplen las reglas de consistencia.');
            COMMIT TRANSACTION;
            SELECT 'RECHAZADA' AS resultado,@id_venta AS id_venta,@suma_detalle AS subtotal_detalle;
            RETURN;
        END;

        UPDATE dbo.Ventas SET estado='completada' WHERE id_venta=@id_venta;
        INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle)
        VALUES('Ventas','VALIDACION',CONVERT(NVARCHAR(100),@id_venta),'Venta validada y marcada como completada.');
        COMMIT TRANSACTION;
        SELECT 'COMPLETADA' AS resultado,@id_venta AS id_venta,@suma_detalle AS subtotal_detalle;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        BEGIN TRY INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,clave_registro,detalle) VALUES('Ventas','ERROR',CONVERT(NVARCHAR(100),@id_venta),ERROR_MESSAGE()); END TRY BEGIN CATCH END CATCH;
        THROW;
    END CATCH
END;
GO

/* 4. Consulta de expansión. Devuelve distritos con una masa crítica
   configurable de clientes y sin una tienda operativa. */
CREATE OR ALTER PROCEDURE dbo.sp_EvaluarExpansionSucursal
    @minimo_clientes INT=50
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT c.distrito,
               COUNT(DISTINCT c.id_cliente) AS clientes_registrados,
               COUNT(DISTINCT CASE WHEN v.estado='completada' THEN v.id_venta END) AS ventas_generadas,
               COALESCE(AVG(CASE WHEN v.estado='completada' THEN v.total_venta END),0) AS ticket_promedio,
               COALESCE(SUM(CASE WHEN v.estado='completada' THEN v.total_venta END),0) AS facturacion_observada
        FROM dbo.Clientes c
        LEFT JOIN dbo.Ventas v ON v.id_cliente=c.id_cliente
        WHERE NULLIF(LTRIM(RTRIM(c.distrito)),'') IS NOT NULL
          AND NOT EXISTS(SELECT 1 FROM dbo.Sucursales s WHERE s.vende=1 AND s.distrito=c.distrito)
        GROUP BY c.distrito
        HAVING COUNT(DISTINCT c.id_cliente)>=@minimo_clientes
        ORDER BY facturacion_observada DESC;
        INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,detalle)
        VALUES('Sucursales','ANALISIS',CONCAT('Expansion evaluada con minimo de ',@minimo_clientes,' clientes.'));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,detalle) VALUES('Sucursales','ERROR',ERROR_MESSAGE()); THROW;
    END CATCH
END;
GO

/* 5. Efectividad de promoción. DATEFIRST queda fijado para que el
   significado de 1..7 no dependa de la configuración regional. */
CREATE OR ALTER PROCEDURE dbo.sp_EfectividadPromocion
    @id_categoria INT,
    @dia_promocion TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFIRST 7; -- domingo=1, lunes=2, ..., sábado=7
    IF @dia_promocion NOT BETWEEN 1 AND 7 THROW 51030,'El dia de promocion debe estar entre 1 y 7.',1;
    BEGIN TRY
        SELECT CASE WHEN DATEPART(WEEKDAY,v.fecha_venta)=@dia_promocion THEN 'Dia de promocion' ELSE 'Dia normal' END AS tipo_dia,
               COUNT(DISTINCT v.id_venta) AS numero_ventas,
               SUM(dv.cantidad) AS unidades_vendidas,
               SUM(dv.subtotal) AS monto_vendido,
               CAST(SUM(dv.subtotal)*1.0/NULLIF(COUNT(DISTINCT CAST(v.fecha_venta AS DATE)),0) AS DECIMAL(12,2)) AS promedio_monto_por_dia
        FROM dbo.Ventas v
        INNER JOIN dbo.DetalleVentas dv ON dv.id_venta=v.id_venta
        INNER JOIN dbo.Productos p ON p.id_producto=dv.id_producto
        WHERE p.id_categoria=@id_categoria AND v.estado='completada'
        GROUP BY CASE WHEN DATEPART(WEEKDAY,v.fecha_venta)=@dia_promocion THEN 'Dia de promocion' ELSE 'Dia normal' END;
        INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,detalle)
        VALUES('Productos','ANALISIS',CONCAT('Efectividad evaluada para categoria=',@id_categoria,' dia=',@dia_promocion));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,detalle) VALUES('Productos','ERROR',ERROR_MESSAGE()); THROW;
    END CATCH
END;
GO

/* 6. Resumen operativo por sucursal. Se añade para que el modelo no
   quede limitado a validaciones: también genera información útil para
   la gestión diaria. */
CREATE OR ALTER PROCEDURE dbo.sp_ResumenVentasSucursal
    @fecha_ini DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;
    IF @fecha_ini>@fecha_fin THROW 51040,'La fecha inicial no puede ser posterior a la fecha final.',1;
    SELECT s.id_sucursal,s.nombre AS sucursal,
           COUNT(DISTINCT v.id_venta) AS ventas,
           COALESCE(SUM(v.total_venta),0) AS facturacion,
           CAST(COALESCE(AVG(v.total_venta),0) AS DECIMAL(12,2)) AS ticket_promedio
    FROM dbo.Sucursales s
    LEFT JOIN dbo.Ventas v ON v.id_sucursal=s.id_sucursal AND v.estado='completada'
      AND CAST(v.fecha_venta AS DATE) BETWEEN @fecha_ini AND @fecha_fin
    WHERE s.vende=1
    GROUP BY s.id_sucursal,s.nombre
    ORDER BY facturacion DESC;
END;
GO
