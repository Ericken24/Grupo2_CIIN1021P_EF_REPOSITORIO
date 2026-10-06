/* ================================================================
   KUSI MINIMARKET — SCRIPT 09
   Funciones reutilizables
   ================================================================

   Las funciones concentran cálculos que se repiten en consultas,
   reportes y procesos del negocio.
*/
USE KUSI_MINIMARKET;
GO

/* 1. Ticket promedio de una sucursal en un periodo. */
CREATE OR ALTER FUNCTION dbo.fn_TicketPromedioSucursal(@id_sucursal INT,@fecha_ini DATE,@fecha_fin DATE)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @resultado DECIMAL(12,2);
    SELECT @resultado=COALESCE(AVG(total_venta),0)
    FROM dbo.Ventas
    WHERE id_sucursal=@id_sucursal AND estado='completada'
      AND fecha_venta>=CAST(@fecha_ini AS DATETIME2)
      AND fecha_venta<DATEADD(DAY,1,CAST(@fecha_fin AS DATETIME2));
    RETURN @resultado;
END;
GO

/* 2. Clasificación sencilla por frecuencia de compras. */
CREATE OR ALTER FUNCTION dbo.fn_ClasificarCliente(@id_cliente INT)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @compras INT,@clasificacion VARCHAR(20);
    SELECT @compras=COUNT(*) FROM dbo.Ventas WHERE id_cliente=@id_cliente AND estado='completada';
    SET @clasificacion=CASE WHEN @compras>=20 THEN 'Frecuente'
                            WHEN @compras BETWEEN 3 AND 19 THEN 'Ocasional'
                            WHEN @compras BETWEEN 1 AND 2 THEN 'Nuevo'
                            ELSE 'Sin compras' END;
    RETURN @clasificacion;
END;
GO

/* 3. Función de tabla para reabastecimiento. */
CREATE OR ALTER FUNCTION dbo.fn_ProductosParaReabastecer()
RETURNS TABLE
AS
RETURN
(
    SELECT p.id_producto,p.nombre_producto,p.stock,p.stock_minimo,
           p.stock_minimo-p.stock AS unidades_faltantes,
           pr.nombre_proveedor,pr.telefono AS telefono_proveedor
    FROM dbo.Productos p INNER JOIN dbo.Proveedores pr ON pr.id_proveedor=p.id_proveedor
    WHERE p.stock<=p.stock_minimo AND p.activo=1
);
GO

/* 4. Función adicional: porcentaje de ventas anónimas de una sucursal. */
CREATE OR ALTER FUNCTION dbo.fn_PorcentajeVentasAnonimas(@id_sucursal INT,@fecha_ini DATE,@fecha_fin DATE)
RETURNS DECIMAL(6,2)
AS
BEGIN
    DECLARE @total INT,@anonimas INT;
    SELECT @total=COUNT(*) FROM dbo.Ventas WHERE id_sucursal=@id_sucursal AND estado='completada'
      AND fecha_venta>=CAST(@fecha_ini AS DATETIME2) AND fecha_venta<DATEADD(DAY,1,CAST(@fecha_fin AS DATETIME2));
    SELECT @anonimas=COUNT(*) FROM dbo.Ventas WHERE id_sucursal=@id_sucursal AND estado='completada' AND id_cliente IS NULL
      AND fecha_venta>=CAST(@fecha_ini AS DATETIME2) AND fecha_venta<DATEADD(DAY,1,CAST(@fecha_fin AS DATETIME2));
    RETURN CAST(CASE WHEN @total=0 THEN 0 ELSE (@anonimas*100.0/@total) END AS DECIMAL(6,2));
END;
GO

SELECT dbo.fn_TicketPromedioSucursal(1,'2024-01-01','2024-12-31') AS ticket_sucursal_1;
SELECT dbo.fn_ClasificarCliente(1473) AS clasificacion_cliente_1;
SELECT * FROM dbo.fn_ProductosParaReabastecer() ORDER BY unidades_faltantes DESC;
SELECT dbo.fn_PorcentajeVentasAnonimas(1,'2024-01-01','2024-12-31') AS porcentaje_anonimo_sucursal_1;
GO