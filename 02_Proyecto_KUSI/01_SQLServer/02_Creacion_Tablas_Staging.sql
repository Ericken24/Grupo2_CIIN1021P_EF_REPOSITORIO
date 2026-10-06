/* ================================================================
   SCRIPT 02: TABLAS DE STAGING (esquema stg)
   ------------------------------------------------------------
   Idea central: todas las columnas son VARCHAR. En staging no
   validamos nada todavia, solo "atrapamos" el archivo tal cual
   viene. La validacion de tipos, fechas y reglas de negocio pasa
   despues, en el script 06 (carga a dbo) y en el script 04
   (auditoria de calidad).
   ================================================================ */

USE KUSI_MINIMARKET;
GO
SET NOCOUNT ON;
GO

/* ---------- 1. Categorias ---------- */
CREATE TABLE stg.CategoriasRaw (
    id_categoria       VARCHAR(50)   NULL,
    nombre_categoria   VARCHAR(200)  NULL,
    descripcion        VARCHAR(1000) NULL,
    activa             VARCHAR(50)   NULL
);
GO

/* ---------- 2. Proveedores ---------- */
CREATE TABLE stg.ProveedoresRaw (
    id_proveedor       VARCHAR(50)   NULL,
    ruc                VARCHAR(50)   NULL,
    nombre_proveedor   VARCHAR(300)  NULL,
    direccion          VARCHAR(500)  NULL,
    telefono           VARCHAR(50)   NULL,
    email              VARCHAR(250)  NULL,
    fecha_registro     VARCHAR(50)   NULL,
    activo             VARCHAR(50)   NULL
);
GO

/* ---------- 3. Sucursales ---------- */
CREATE TABLE stg.SucursalesRaw (
    id                 VARCHAR(50)   NULL,
    nombre             VARCHAR(300)  NULL,
    direccion          VARCHAR(500)  NULL,
    ciudad             VARCHAR(150)  NULL,
    distrito           VARCHAR(150)  NULL,
    tipo               VARCHAR(100)  NULL,
    vende              VARCHAR(50)   NULL,
    apertura           VARCHAR(50)   NULL,
    flujo              VARCHAR(50)   NULL,
    ticket             VARCHAR(50)   NULL
);
GO

/* ---------- 4. Metodos de pago ---------- */
CREATE TABLE stg.MetodosPagoRaw (
    id_metodo_pago     VARCHAR(50)   NULL,
    nombre_metodo      VARCHAR(150)  NULL,
    tipo               VARCHAR(100)  NULL,
    activo             VARCHAR(50)   NULL
);
GO

/* ---------- 5. Productos ---------- */
CREATE TABLE stg.ProductosRaw (
    id_producto        VARCHAR(50)   NULL,
    codigo_barras      VARCHAR(100)  NULL,
    nombre_producto    VARCHAR(300)  NULL,
    id_categoria       VARCHAR(50)   NULL,
    id_proveedor       VARCHAR(50)   NULL,
    precio_compra      VARCHAR(50)   NULL,
    precio_venta       VARCHAR(50)   NULL,
    stock              VARCHAR(50)   NULL,
    stock_minimo       VARCHAR(50)   NULL,
    unidad_medida      VARCHAR(100)  NULL,
    fecha_registro     VARCHAR(50)   NULL,
    activo             VARCHAR(50)   NULL
);
GO

/* ---------- 6. Empleados ---------- */
CREATE TABLE stg.EmpleadosRaw (
    id_empleado        VARCHAR(50)   NULL,
    dni                VARCHAR(50)   NULL,
    nombre_completo    VARCHAR(300)  NULL,
    cargo              VARCHAR(150)  NULL,
    id_sucursal        VARCHAR(50)   NULL,
    telefono           VARCHAR(50)   NULL,
    fecha_ingreso      VARCHAR(50)   NULL,
    activo             VARCHAR(50)   NULL
);
GO

/* ---------- 7. Clientes ---------- */
CREATE TABLE stg.ClientesRaw (
    id_cliente             VARCHAR(50)   NULL,
    dni                    VARCHAR(50)   NULL,
    nombre_completo        VARCHAR(300)  NULL,
    telefono               VARCHAR(50)   NULL,
    email                  VARCHAR(300)  NULL,
    direccion              VARCHAR(500)  NULL,
    distrito               VARCHAR(150)  NULL,
    fecha_registro         VARCHAR(50)   NULL,
    consentimiento_datos   VARCHAR(50)   NULL,
    activo                 VARCHAR(50)   NULL
);
GO

/* ---------- 8. Ventas (cabecera) ---------- */
CREATE TABLE stg.VentasRaw (
    id_venta             VARCHAR(50)   NULL,
    id_cliente           VARCHAR(50)   NULL,
    id_empleado          VARCHAR(50)   NULL,
    id_sucursal          VARCHAR(50)   NULL,
    id_metodo_pago       VARCHAR(50)   NULL,
    fecha_venta          VARCHAR(50)   NULL,
    subtotal             VARCHAR(50)   NULL,
    igv                  VARCHAR(50)   NULL,
    total_venta          VARCHAR(50)   NULL,
    numero_comprobante   VARCHAR(100)  NULL,
    tipo_comprobante     VARCHAR(50)   NULL,
    estado               VARCHAR(50)   NULL
);
GO

/* ---------- 9. Detalle de ventas ---------- */
CREATE TABLE stg.DetalleVentasRaw (
    id_detalle          VARCHAR(50)   NULL,
    id_venta            VARCHAR(50)   NULL,
    id_producto         VARCHAR(50)   NULL,
    cantidad            VARCHAR(50)   NULL,
    precio_unitario     VARCHAR(50)   NULL,
    subtotal            VARCHAR(50)   NULL
);
GO

/* ---------- 10. Compras (cabecera) ---------- */
CREATE TABLE stg.ComprasRaw (
    id_compra          VARCHAR(50)   NULL,
    id_proveedor       VARCHAR(50)   NULL,
    id_sucursal        VARCHAR(50)   NULL,
    fecha_compra       VARCHAR(50)   NULL,
    total_compra       VARCHAR(50)   NULL,
    numero_factura     VARCHAR(100)  NULL,
    estado             VARCHAR(50)   NULL
);
GO

/* ---------- 11. Detalle de compras ---------- */
CREATE TABLE stg.DetalleComprasRaw (
    id_detalle_compra   VARCHAR(50)   NULL,
    id_compra           VARCHAR(50)   NULL,
    id_producto         VARCHAR(50)   NULL,
    cantidad             VARCHAR(50)   NULL,
    precio_unitario      VARCHAR(50)   NULL,
    subtotal             VARCHAR(50)   NULL
);
GO

/* Verificacion: deben aparecer las 11 tablas de staging */
SELECT TABLE_SCHEMA AS esquema, TABLE_NAME AS tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'stg'
ORDER BY TABLE_NAME;
GO
