/* ================================================================
   SCRIPT 03: CARGA DE LOS CSV A STAGING (BULK INSERT)
   ------------------------------------------------------------
   IMPORTANTE ANTES DE EJECUTAR:
   Cambia la ruta @Ruta por la carpeta donde tengas los 11 archivos
   CSV en tu maquina (o en el servidor donde corre SQL Server).
   Los archivos deben estar en UTF-8 con encabezado en la fila 1.
   ================================================================ */

USE KUSI_MINIMARKET;
GO
SET NOCOUNT ON;

DECLARE @Ruta NVARCHAR(400) = N'C:\KUSI_MINIMARKET\CSV_SQL\';
-- Nota: BULK INSERT no acepta variables directamente en el FROM,
-- por eso cada bloque de abajo repite la ruta tal cual.

/* ==========================================================
   TIPO A: UTF-8 con BOM + saltos CRLF  (sin ROWTERMINATOR)
   ========================================================== */
 
TRUNCATE TABLE stg.CategoriasRaw;
BULK INSERT stg.CategoriasRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\categorias.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.ProveedoresRaw;
BULK INSERT stg.ProveedoresRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\proveedores.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.MetodosPagoRaw;
BULK INSERT stg.MetodosPagoRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\metodos_pago.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.ProductosRaw;
BULK INSERT stg.ProductosRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\productos.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.ClientesRaw;
BULK INSERT stg.ClientesRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\clientes.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
 
/* ==========================================================
   TIPO B: UTF-8 sin BOM + saltos LF  (ROWTERMINATOR='0x0a')
   ========================================================== */
 
TRUNCATE TABLE stg.SucursalesRaw;
BULK INSERT stg.SucursalesRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\sucursales.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.EmpleadosRaw;   -- antes apuntaba a SucursalesRaw
BULK INSERT stg.EmpleadosRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\empleados.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.ComprasRaw;
BULK INSERT stg.ComprasRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\compras.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.DetalleComprasRaw;
BULK INSERT stg.DetalleComprasRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\detalle_compras.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.VentasRaw;
BULK INSERT stg.VentasRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\ventas.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);
 
TRUNCATE TABLE stg.DetalleVentasRaw;
BULK INSERT stg.DetalleVentasRaw FROM 'C:\KUSI_MINIMARKET\CSV_SQL\detalle_ventas.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);
GO

/* ------------------------------------------------------------
   Verificacion final: conteo de filas cargadas por tabla.
   Compara estos numeros contra tu ficha de relevamiento
   (515 productos, 2500 clientes, 180000 ventas, etc).
   ------------------------------------------------------------ */
SELECT 'categorias'      AS tabla, COUNT(*) AS registros FROM stg.CategoriasRaw
UNION ALL SELECT 'proveedores',      COUNT(*) FROM stg.ProveedoresRaw
UNION ALL SELECT 'sucursales',       COUNT(*) FROM stg.SucursalesRaw
UNION ALL SELECT 'metodos_pago',     COUNT(*) FROM stg.MetodosPagoRaw
UNION ALL SELECT 'productos',        COUNT(*) FROM stg.ProductosRaw
UNION ALL SELECT 'empleados',        COUNT(*) FROM stg.EmpleadosRaw
UNION ALL SELECT 'clientes',         COUNT(*) FROM stg.ClientesRaw
UNION ALL SELECT 'compras',          COUNT(*) FROM stg.ComprasRaw
UNION ALL SELECT 'detalle_compras',  COUNT(*) FROM stg.DetalleComprasRaw
UNION ALL SELECT 'ventas',           COUNT(*) FROM stg.VentasRaw
UNION ALL SELECT 'detalle_ventas',   COUNT(*) FROM stg.DetalleVentasRaw;
GO
