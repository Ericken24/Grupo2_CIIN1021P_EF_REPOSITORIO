/* ================================================================
   KUSI MINIMARKET — SCRIPT 04
   Auditoría de calidad en staging
   ================================================================

   Este script diagnostica; no corrige ni elimina registros.
   El objetivo es obtener cifras reproducibles para el relevamiento.
   Cada bloque puede ejecutarse por separado y convertirse en una
   captura de evidencia.
*/
USE KUSI_MINIMARKET;
GO
SET NOCOUNT ON;

/* 1. Volumen y completitud: el NULL de id_cliente representa la
      venta anónima y no se considera un error que deba imputarse. */
SELECT 'ClientesRaw' AS tabla, COUNT(*) AS total,
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(id_cliente)),'') IS NULL THEN 1 ELSE 0 END) AS id_nulo,
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(email)),'') IS NULL THEN 1 ELSE 0 END) AS email_nulo_o_vacio
FROM stg.ClientesRaw
UNION ALL
SELECT 'VentasRaw', COUNT(*),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(id_venta)),'') IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(id_cliente)),'') IS NULL THEN 1 ELSE 0 END)
FROM stg.VentasRaw;
GO

/* 2. Duplicados de claves principales. */
SELECT 'clientes' AS tabla, id_cliente AS llave, COUNT(*) AS repeticiones
FROM stg.ClientesRaw GROUP BY id_cliente HAVING COUNT(*) > 1
UNION ALL
SELECT 'ventas', id_venta, COUNT(*) FROM stg.VentasRaw GROUP BY id_venta HAVING COUNT(*) > 1
UNION ALL
SELECT 'productos', id_producto, COUNT(*) FROM stg.ProductosRaw GROUP BY id_producto HAVING COUNT(*) > 1;
GO

/* 3. Integridad referencial en staging. */
SELECT 'productos_sin_categoria' AS chequeo, COUNT(*) AS casos
FROM stg.ProductosRaw p LEFT JOIN stg.CategoriasRaw c ON LTRIM(RTRIM(p.id_categoria))=LTRIM(RTRIM(c.id_categoria))
WHERE NULLIF(LTRIM(RTRIM(p.id_categoria)),'') IS NOT NULL AND c.id_categoria IS NULL
UNION ALL
SELECT 'productos_sin_proveedor', COUNT(*)
FROM stg.ProductosRaw p LEFT JOIN stg.ProveedoresRaw pr ON LTRIM(RTRIM(p.id_proveedor))=LTRIM(RTRIM(pr.id_proveedor))
WHERE NULLIF(LTRIM(RTRIM(p.id_proveedor)),'') IS NOT NULL AND pr.id_proveedor IS NULL
UNION ALL
SELECT 'ventas_sin_sucursal', COUNT(*)
FROM stg.VentasRaw v LEFT JOIN stg.SucursalesRaw s ON LTRIM(RTRIM(v.id_sucursal))=LTRIM(RTRIM(s.id))
WHERE s.id IS NULL
UNION ALL
SELECT 'ventas_cliente_inexistente', COUNT(*)
FROM stg.VentasRaw v LEFT JOIN stg.ClientesRaw c ON LTRIM(RTRIM(v.id_cliente))=LTRIM(RTRIM(c.id_cliente))
WHERE NULLIF(LTRIM(RTRIM(v.id_cliente)),'') IS NOT NULL AND c.id_cliente IS NULL
UNION ALL
SELECT 'detalle_ventas_sin_venta', COUNT(*)
FROM stg.DetalleVentasRaw dv LEFT JOIN stg.VentasRaw v ON LTRIM(RTRIM(dv.id_venta))=LTRIM(RTRIM(v.id_venta))
WHERE v.id_venta IS NULL
UNION ALL
SELECT 'detalle_ventas_sin_producto', COUNT(*)
FROM stg.DetalleVentasRaw dv LEFT JOIN stg.ProductosRaw p ON LTRIM(RTRIM(dv.id_producto))=LTRIM(RTRIM(p.id_producto))
WHERE p.id_producto IS NULL;
GO

/* 4. Reglas Q01-Q05. Q01 se cuenta sobre la fecha de venta; Q03/Q04
      se cuentan directamente sobre los registros de clientes. */
SELECT 'Q01_FueraPeriodo' AS problema, COUNT(*) AS registros
FROM stg.VentasRaw
WHERE TRY_CONVERT(DATETIME2, fecha_venta) < '2023-01-01'
   OR TRY_CONVERT(DATETIME2, fecha_venta) >= '2025-09-01'
UNION ALL
SELECT 'Q02_VentaAnonima', COUNT(*)
FROM stg.VentasRaw WHERE NULLIF(LTRIM(RTRIM(id_cliente)),'') IS NULL
UNION ALL
SELECT 'Q03_DNIIncorrecto', COUNT(*)
FROM stg.ClientesRaw
WHERE NULLIF(LTRIM(RTRIM(dni)),'') IS NOT NULL AND LEN(LTRIM(RTRIM(dni))) <> 8
UNION ALL
SELECT 'Q04_EmailInvalidoOVacio', COUNT(*)
FROM stg.ClientesRaw
WHERE NULLIF(LTRIM(RTRIM(email)),'') IS NULL
   OR email LIKE '% %'
   OR email NOT LIKE '%_@__%.__%'
UNION ALL
SELECT 'Q05_DistritoConVariante', COUNT(*)
FROM stg.ClientesRaw
WHERE LTRIM(RTRIM(distrito)) COLLATE Latin1_General_100_BIN2 NOT IN
      ('Cajamarca','Baños del Inca','San Sebastián','Llacanora','Jesús','La Encañada','Porcón','Chetilla')
  AND NULLIF(LTRIM(RTRIM(distrito)),'') IS NOT NULL;
GO

/* 5. Reglas Q06-Q08. Estas cifras son independientes: una misma
      venta puede pertenecer a Q06 y Q07. */
SELECT 'Q06_TotalCero' AS problema, COUNT(*) AS registros
FROM stg.VentasRaw WHERE TRY_CONVERT(DECIMAL(12,2), total_venta) = 0
UNION ALL
SELECT 'Q07_SinDetalle', COUNT(*)
FROM stg.VentasRaw v
WHERE NOT EXISTS (SELECT 1 FROM stg.DetalleVentasRaw dv WHERE dv.id_venta=v.id_venta)
UNION ALL
SELECT 'Q08_StockBajoMinimo', COUNT(*)
FROM stg.ProductosRaw
WHERE TRY_CONVERT(INT, stock) <= TRY_CONVERT(INT, stock_minimo);
GO

/* 6. Las 6 ventas únicas afectadas por Q01/Q06/Q07. Esta consulta
      evita sumar incidencias y confundirse con el número de ventas. */
SELECT v.id_venta, v.fecha_venta, v.total_venta,
       CASE WHEN TRY_CONVERT(DATETIME2,v.fecha_venta) < '2023-01-01'
                  OR TRY_CONVERT(DATETIME2,v.fecha_venta) >= '2025-09-01' THEN 1 ELSE 0 END AS Q01,
       CASE WHEN TRY_CONVERT(DECIMAL(12,2),v.total_venta)=0 THEN 1 ELSE 0 END AS Q06,
       CASE WHEN NOT EXISTS (SELECT 1 FROM stg.DetalleVentasRaw dv WHERE dv.id_venta=v.id_venta) THEN 1 ELSE 0 END AS Q07
FROM stg.VentasRaw v
WHERE TRY_CONVERT(DATETIME2,v.fecha_venta) < '2023-01-01'
   OR TRY_CONVERT(DATETIME2,v.fecha_venta) >= '2025-09-01'
   OR TRY_CONVERT(DECIMAL(12,2),v.total_venta)=0
   OR NOT EXISTS (SELECT 1 FROM stg.DetalleVentasRaw dv WHERE dv.id_venta=v.id_venta)
ORDER BY TRY_CONVERT(INT,v.id_venta);
GO

/* 7. Consistencia matemática: se espera cero en un dataset válido. */
SELECT COUNT(*) AS ventas_con_total_inconsistente
FROM stg.VentasRaw
WHERE TRY_CONVERT(DECIMAL(12,2),subtotal) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(12,2),igv) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(12,2),total_venta) IS NOT NULL
  AND ABS(TRY_CONVERT(DECIMAL(12,2),subtotal)+TRY_CONVERT(DECIMAL(12,2),igv)-TRY_CONVERT(DECIMAL(12,2),total_venta)) > 0.01;
GO
