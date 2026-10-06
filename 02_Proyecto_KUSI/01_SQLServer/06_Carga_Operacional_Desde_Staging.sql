/* ================================================================
   KUSI MINIMARKET — SCRIPT 06
   Carga controlada de staging al modelo operacional
   ================================================================

   La fuente queda intacta. Este paso decide qué registros pasan al
   modelo operacional y cuáles quedan en calidad.

   Q06 y Q07 se registran por separado. Si una venta incumple ambas
   reglas, aparecen dos incidencias para el mismo id_venta; no se
   pierde información sobre la causa del rechazo.
*/
USE KUSI_MINIMARKET;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION CargaOperacional;

    INSERT INTO dbo.Categorias(id_categoria,nombre_categoria,descripcion,activa)
    SELECT TRY_CONVERT(INT,id_categoria),nombre_categoria,descripcion,TRY_CONVERT(BIT,activa)
    FROM stg.CategoriasRaw WHERE TRY_CONVERT(INT,id_categoria) IS NOT NULL;

    INSERT INTO dbo.Proveedores(id_proveedor,ruc,nombre_proveedor,direccion,telefono,email,fecha_registro,activo)
    SELECT TRY_CONVERT(INT,id_proveedor),ruc,nombre_proveedor,direccion,telefono,email,TRY_CONVERT(DATE,fecha_registro),TRY_CONVERT(BIT,activo)
    FROM stg.ProveedoresRaw WHERE TRY_CONVERT(INT,id_proveedor) IS NOT NULL;

    INSERT INTO dbo.Sucursales(id_sucursal,nombre,direccion,ciudad,distrito,tipo,vende,apertura,flujo,ticket)
    SELECT TRY_CONVERT(INT,id),nombre,direccion,ciudad,distrito,tipo,TRY_CONVERT(BIT,vende),TRY_CONVERT(DATE,apertura),flujo,TRY_CONVERT(DECIMAL(10,2),ticket)
    FROM stg.SucursalesRaw WHERE TRY_CONVERT(INT,id) IS NOT NULL;

    INSERT INTO dbo.MetodosPago(id_metodo_pago,nombre_metodo,tipo,activo)
    SELECT TRY_CONVERT(INT,id_metodo_pago),nombre_metodo,tipo,TRY_CONVERT(BIT,activo)
    FROM stg.MetodosPagoRaw WHERE TRY_CONVERT(INT,id_metodo_pago) IS NOT NULL;

    INSERT INTO dbo.Productos(id_producto,codigo_barras,nombre_producto,id_categoria,id_proveedor,precio_compra,precio_venta,stock,stock_minimo,unidad_medida,fecha_registro,activo)
    SELECT TRY_CONVERT(INT,p.id_producto),p.codigo_barras,p.nombre_producto,TRY_CONVERT(INT,p.id_categoria),TRY_CONVERT(INT,p.id_proveedor),
           TRY_CONVERT(DECIMAL(10,2),p.precio_compra),TRY_CONVERT(DECIMAL(10,2),p.precio_venta),TRY_CONVERT(INT,p.stock),TRY_CONVERT(INT,p.stock_minimo),p.unidad_medida,TRY_CONVERT(DATE,p.fecha_registro),TRY_CONVERT(BIT,p.activo)
    FROM stg.ProductosRaw p
    WHERE TRY_CONVERT(INT,p.id_producto) IS NOT NULL
      AND EXISTS(SELECT 1 FROM dbo.Categorias c WHERE c.id_categoria=TRY_CONVERT(INT,p.id_categoria))
      AND EXISTS(SELECT 1 FROM dbo.Proveedores pr WHERE pr.id_proveedor=TRY_CONVERT(INT,p.id_proveedor));

    INSERT INTO dbo.Empleados(id_empleado,dni,nombre_completo,cargo,id_sucursal,telefono,fecha_ingreso,activo)
    SELECT TRY_CONVERT(INT,e.id_empleado),e.dni,e.nombre_completo,e.cargo,TRY_CONVERT(INT,e.id_sucursal),e.telefono,TRY_CONVERT(DATE,e.fecha_ingreso),TRY_CONVERT(BIT,e.activo)
    FROM stg.EmpleadosRaw e
    WHERE TRY_CONVERT(INT,e.id_empleado) IS NOT NULL
      AND EXISTS(SELECT 1 FROM dbo.Sucursales s WHERE s.id_sucursal=TRY_CONVERT(INT,e.id_sucursal));

    INSERT INTO dbo.Clientes(id_cliente,dni,nombre_completo,telefono,email,direccion,distrito,fecha_registro,consentimiento_datos,activo)
    SELECT TRY_CONVERT(INT,id_cliente),dni,nombre_completo,telefono,email,direccion,distrito,TRY_CONVERT(DATE,fecha_registro),TRY_CONVERT(BIT,consentimiento_datos),TRY_CONVERT(BIT,activo)
    FROM stg.ClientesRaw WHERE TRY_CONVERT(INT,id_cliente) IS NOT NULL;

    INSERT INTO calidad.ClientesObservados(id_cliente_origen,motivo_observacion)
    SELECT id_cliente,'DNI con longitud distinta de 8 (Q03)'
    FROM stg.ClientesRaw
    WHERE NULLIF(LTRIM(RTRIM(dni)),'') IS NOT NULL AND LEN(LTRIM(RTRIM(dni)))<>8
    UNION ALL
    SELECT id_cliente,'Email con formato invalido o vacio (Q04)'
    FROM stg.ClientesRaw
    WHERE NULLIF(LTRIM(RTRIM(email)),'') IS NULL OR email LIKE '% %' OR email NOT LIKE '%_@__%.__%';

    /* Ventas válidas: además de tener total positivo y detalle,
       deben apuntar a las maestras existentes. */
    INSERT INTO dbo.Ventas(id_venta,id_cliente,id_empleado,id_sucursal,id_metodo_pago,fecha_venta,subtotal,igv,total_venta,numero_comprobante,tipo_comprobante,estado)
    SELECT TRY_CONVERT(INT,v.id_venta),TRY_CONVERT(INT,v.id_cliente),TRY_CONVERT(INT,v.id_empleado),TRY_CONVERT(INT,v.id_sucursal),TRY_CONVERT(INT,v.id_metodo_pago),
           TRY_CONVERT(DATETIME2,v.fecha_venta),TRY_CONVERT(DECIMAL(12,2),v.subtotal),TRY_CONVERT(DECIMAL(12,2),v.igv),TRY_CONVERT(DECIMAL(12,2),v.total_venta),v.numero_comprobante,v.tipo_comprobante,v.estado
    FROM stg.VentasRaw v
    WHERE TRY_CONVERT(INT,v.id_venta) IS NOT NULL
      AND TRY_CONVERT(DECIMAL(12,2),v.total_venta)>0
      AND EXISTS(SELECT 1 FROM stg.DetalleVentasRaw dv WHERE dv.id_venta=v.id_venta)
      AND EXISTS(SELECT 1 FROM dbo.Empleados e WHERE e.id_empleado=TRY_CONVERT(INT,v.id_empleado))
      AND EXISTS(SELECT 1 FROM dbo.Sucursales s WHERE s.id_sucursal=TRY_CONVERT(INT,v.id_sucursal))
      AND EXISTS(SELECT 1 FROM dbo.MetodosPago m WHERE m.id_metodo_pago=TRY_CONVERT(INT,v.id_metodo_pago));

    /* Q06: total cero. */
    INSERT INTO calidad.VentasRechazadas(id_venta_origen,motivo_rechazo,datos_originales)
    SELECT id_venta,'Venta con total en cero (Q06)',CONCAT('fecha=',fecha_venta,' total=',total_venta)
    FROM stg.VentasRaw WHERE TRY_CONVERT(DECIMAL(12,2),total_venta)=0;

    /* Q07: cabecera sin detalle. */
    INSERT INTO calidad.VentasRechazadas(id_venta_origen,motivo_rechazo,datos_originales)
    SELECT v.id_venta,'Venta de cabecera sin ningun detalle (Q07)',CONCAT('fecha=',v.fecha_venta,' total=',v.total_venta)
    FROM stg.VentasRaw v
    WHERE NOT EXISTS(SELECT 1 FROM stg.DetalleVentasRaw dv WHERE dv.id_venta=v.id_venta);

    /* Q01 no es un rechazo operacional: se conserva en dbo para trazabilidad
       y se marca como observación. El filtro temporal se aplicará al DW. */
    INSERT INTO calidad.VentasObservadas(id_venta_origen,motivo_observacion,datos_originales)
    SELECT v.id_venta,'Venta fuera del periodo analitico (Q01)',CONCAT('fecha=',v.fecha_venta,' total=',v.total_venta)
    FROM stg.VentasRaw v
    WHERE TRY_CONVERT(DATETIME2,v.fecha_venta)<'2023-01-01'
       OR TRY_CONVERT(DATETIME2,v.fecha_venta)>='2025-09-01';

    INSERT INTO dbo.Compras(id_compra,id_proveedor,id_sucursal,fecha_compra,total_compra,numero_factura,estado)
    SELECT TRY_CONVERT(INT,c.id_compra),TRY_CONVERT(INT,c.id_proveedor),TRY_CONVERT(INT,c.id_sucursal),TRY_CONVERT(DATETIME2,c.fecha_compra),TRY_CONVERT(DECIMAL(12,2),c.total_compra),c.numero_factura,c.estado
    FROM stg.ComprasRaw c
    WHERE TRY_CONVERT(INT,c.id_compra) IS NOT NULL
      AND EXISTS(SELECT 1 FROM dbo.Proveedores p WHERE p.id_proveedor=TRY_CONVERT(INT,c.id_proveedor))
      AND EXISTS(SELECT 1 FROM dbo.Sucursales s WHERE s.id_sucursal=TRY_CONVERT(INT,c.id_sucursal));

    INSERT INTO dbo.DetalleVentas(id_detalle,id_venta,id_producto,cantidad,precio_unitario,subtotal)
    SELECT TRY_CONVERT(INT,dv.id_detalle),TRY_CONVERT(INT,dv.id_venta),TRY_CONVERT(INT,dv.id_producto),TRY_CONVERT(INT,dv.cantidad),TRY_CONVERT(DECIMAL(10,2),dv.precio_unitario),TRY_CONVERT(DECIMAL(12,2),dv.subtotal)
    FROM stg.DetalleVentasRaw dv
    WHERE TRY_CONVERT(INT,dv.id_detalle) IS NOT NULL
      AND EXISTS(SELECT 1 FROM dbo.Ventas v WHERE v.id_venta=TRY_CONVERT(INT,dv.id_venta))
      AND EXISTS(SELECT 1 FROM dbo.Productos p WHERE p.id_producto=TRY_CONVERT(INT,dv.id_producto));

    INSERT INTO dbo.DetalleCompras(id_detalle_compra,id_compra,id_producto,cantidad,precio_unitario,subtotal)
    SELECT TRY_CONVERT(INT,dc.id_detalle_compra),TRY_CONVERT(INT,dc.id_compra),TRY_CONVERT(INT,dc.id_producto),TRY_CONVERT(INT,dc.cantidad),TRY_CONVERT(DECIMAL(10,2),dc.precio_unitario),TRY_CONVERT(DECIMAL(12,2),dc.subtotal)
    FROM stg.DetalleComprasRaw dc
    WHERE TRY_CONVERT(INT,dc.id_detalle_compra) IS NOT NULL
      AND EXISTS(SELECT 1 FROM dbo.Compras c WHERE c.id_compra=TRY_CONVERT(INT,dc.id_compra))
      AND EXISTS(SELECT 1 FROM dbo.Productos p WHERE p.id_producto=TRY_CONVERT(INT,dc.id_producto));

    INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,detalle)
    VALUES('dbo.*','CARGA','Carga de staging a modelo operacional completada.');

    COMMIT TRANSACTION CargaOperacional;
    PRINT 'Carga operacional confirmada con COMMIT.';
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION CargaOperacional;
    INSERT INTO audit.LogAuditoria(tabla_afectada,operacion,detalle)
    VALUES('dbo.*','ERROR',ERROR_MESSAGE());
    THROW;
END CATCH;
GO

SELECT 'Ventas' AS tabla, COUNT(*) AS registros FROM dbo.Ventas
UNION ALL SELECT 'DetalleVentas',COUNT(*) FROM dbo.DetalleVentas
UNION ALL SELECT 'VentasRechazadas',COUNT(*) FROM calidad.VentasRechazadas
UNION ALL SELECT 'VentasObservadas',COUNT(*) FROM calidad.VentasObservadas
UNION ALL SELECT 'ClientesObservados',COUNT(*) FROM calidad.ClientesObservados;
GO
