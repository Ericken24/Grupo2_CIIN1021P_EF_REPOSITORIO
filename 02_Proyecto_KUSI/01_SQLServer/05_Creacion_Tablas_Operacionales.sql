/* ================================================================
   SCRIPT 05: TABLAS OPERACIONALES (esquema dbo) + TABLAS DE CALIDAD
   ------------------------------------------------------------
   Aqui vive el modelo relacional "oficial" del minimarket, ya
   tipado y con reglas (PK, FK, CHECK). Los datos llegan desde
   staging DESPUES de pasar la validacion (ver script 06).
   Tambien creamos aqui la tabla de auditoria y las tablas de
   cuarentena del esquema calidad, para que todo el modelo quede
   listo antes de cargar un solo dato.
   ================================================================ */

USE KUSI_MINIMARKET;
GO
SET NOCOUNT ON;
GO

/* ============================================================
   NIVEL 1 - TABLAS MAESTRAS INDEPENDIENTES
   ============================================================ */

CREATE TABLE dbo.Categorias (
    id_categoria       INT             NOT NULL,
    nombre_categoria   NVARCHAR(100)   NOT NULL,
    descripcion        NVARCHAR(500)   NULL,
    activa             BIT             NOT NULL CONSTRAINT DF_Categorias_Activa DEFAULT (1),
    CONSTRAINT PK_Categorias PRIMARY KEY (id_categoria),
    CONSTRAINT UQ_Categorias_Nombre UNIQUE (nombre_categoria)
);
GO

CREATE TABLE dbo.Proveedores (
    id_proveedor       INT             NOT NULL,
    ruc                VARCHAR(11)     NULL,
    nombre_proveedor   NVARCHAR(200)   NOT NULL,
    direccion          NVARCHAR(300)   NULL,
    telefono           VARCHAR(20)     NULL,
    email              VARCHAR(150)    NULL,
    fecha_registro     DATE            NULL,
    activo             BIT             NOT NULL CONSTRAINT DF_Proveedores_Activo DEFAULT (1),
    CONSTRAINT PK_Proveedores PRIMARY KEY (id_proveedor),
    CONSTRAINT UQ_Proveedores_RUC UNIQUE (ruc)
);
GO

CREATE TABLE dbo.Sucursales (
    id_sucursal        INT             NOT NULL,
    nombre             NVARCHAR(150)   NOT NULL,
    direccion          NVARCHAR(300)   NULL,
    ciudad             NVARCHAR(100)   NULL,
    distrito           NVARCHAR(100)   NULL,
    tipo               NVARCHAR(50)    NULL,
    vende              BIT             NOT NULL,
    apertura           DATE            NULL,
    flujo              NVARCHAR(50)    NULL,
    ticket             DECIMAL(10,2)   NULL,
    CONSTRAINT PK_Sucursales PRIMARY KEY (id_sucursal),
    CONSTRAINT CK_Sucursales_Ticket CHECK (ticket IS NULL OR ticket >= 0)
);
GO

CREATE TABLE dbo.MetodosPago (
    id_metodo_pago     INT             NOT NULL,
    nombre_metodo      NVARCHAR(100)   NOT NULL,
    tipo               NVARCHAR(50)    NULL,
    activo             BIT             NOT NULL CONSTRAINT DF_MetodosPago_Activo DEFAULT (1),
    CONSTRAINT PK_MetodosPago PRIMARY KEY (id_metodo_pago),
    CONSTRAINT UQ_MetodosPago_Nombre UNIQUE (nombre_metodo)
);
GO

/* ============================================================
   NIVEL 2 - TABLAS MAESTRAS DEPENDIENTES
   ============================================================ */

CREATE TABLE dbo.Productos (
    id_producto        INT             NOT NULL,
    codigo_barras      VARCHAR(50)     NULL,
    nombre_producto    NVARCHAR(250)   NOT NULL,
    id_categoria       INT             NOT NULL,
    id_proveedor       INT             NOT NULL,
    precio_compra      DECIMAL(10,2)   NOT NULL,
    precio_venta       DECIMAL(10,2)   NOT NULL,
    stock              INT             NOT NULL,
    stock_minimo       INT             NOT NULL,
    unidad_medida      NVARCHAR(50)    NULL,
    fecha_registro     DATE            NULL,
    activo             BIT             NOT NULL CONSTRAINT DF_Productos_Activo DEFAULT (1),
    CONSTRAINT PK_Productos PRIMARY KEY (id_producto),
    CONSTRAINT FK_Productos_Categorias FOREIGN KEY (id_categoria) REFERENCES dbo.Categorias(id_categoria),
    CONSTRAINT FK_Productos_Proveedores FOREIGN KEY (id_proveedor) REFERENCES dbo.Proveedores(id_proveedor),
    CONSTRAINT UQ_Productos_CodigoBarras UNIQUE (codigo_barras),
    CONSTRAINT CK_Productos_PrecioCompra CHECK (precio_compra >= 0),
    CONSTRAINT CK_Productos_PrecioVenta CHECK (precio_venta > precio_compra),
    CONSTRAINT CK_Productos_Stock CHECK (stock >= 0),
    CONSTRAINT CK_Productos_StockMinimo CHECK (stock_minimo >= 0)
);
GO

CREATE TABLE dbo.Empleados (
    id_empleado        INT             NOT NULL,
    dni                VARCHAR(20)     NULL,
    nombre_completo    NVARCHAR(200)   NOT NULL,
    cargo              NVARCHAR(100)   NULL,
    id_sucursal        INT             NOT NULL,
    telefono           VARCHAR(20)     NULL,
    fecha_ingreso      DATE            NULL,
    activo             BIT             NOT NULL CONSTRAINT DF_Empleados_Activo DEFAULT (1),
    CONSTRAINT PK_Empleados PRIMARY KEY (id_empleado),
    CONSTRAINT FK_Empleados_Sucursales FOREIGN KEY (id_sucursal) REFERENCES dbo.Sucursales(id_sucursal)
);
GO

CREATE TABLE dbo.Clientes (
    id_cliente             INT             NOT NULL,
    dni                    VARCHAR(20)     NULL,
    nombre_completo        NVARCHAR(200)   NULL,
    telefono               VARCHAR(20)     NULL,
    email                  VARCHAR(150)    NULL,
    direccion              NVARCHAR(300)   NULL,
    distrito               NVARCHAR(100)   NULL,
    fecha_registro         DATE            NULL,
    consentimiento_datos   BIT             NULL,
    activo                 BIT             NOT NULL CONSTRAINT DF_Clientes_Activo DEFAULT (1),
    CONSTRAINT PK_Clientes PRIMARY KEY (id_cliente)
);
GO

/* ============================================================
   NIVEL 3 - CABECERAS TRANSACCIONALES
   ============================================================ */

CREATE TABLE dbo.Ventas (
    id_venta             INT             NOT NULL,
    id_cliente           INT             NULL,
    id_empleado          INT             NOT NULL,
    id_sucursal          INT             NOT NULL,
    id_metodo_pago       INT             NOT NULL,
    fecha_venta          DATETIME2(0)    NOT NULL,
    subtotal             DECIMAL(12,2)   NOT NULL,
    igv                  DECIMAL(12,2)   NOT NULL,
    total_venta          DECIMAL(12,2)   NOT NULL,
    numero_comprobante   VARCHAR(50)     NULL,
    tipo_comprobante     VARCHAR(20)     NULL,
    estado               VARCHAR(20)     NOT NULL,
    CONSTRAINT PK_Ventas PRIMARY KEY (id_venta),
    CONSTRAINT FK_Ventas_Clientes FOREIGN KEY (id_cliente) REFERENCES dbo.Clientes(id_cliente),
    CONSTRAINT FK_Ventas_Empleados FOREIGN KEY (id_empleado) REFERENCES dbo.Empleados(id_empleado),
    CONSTRAINT FK_Ventas_Sucursales FOREIGN KEY (id_sucursal) REFERENCES dbo.Sucursales(id_sucursal),
    CONSTRAINT FK_Ventas_MetodosPago FOREIGN KEY (id_metodo_pago) REFERENCES dbo.MetodosPago(id_metodo_pago),
    CONSTRAINT CK_Ventas_Subtotal CHECK (subtotal >= 0),
    CONSTRAINT CK_Ventas_IGV CHECK (igv >= 0),
    CONSTRAINT CK_Ventas_Total CHECK (total_venta > 0),
    CONSTRAINT CK_Ventas_Estado CHECK (estado IN ('pendiente','completada','rechazada','anulada'))
);
GO

CREATE TABLE dbo.Compras (
    id_compra          INT             NOT NULL,
    id_proveedor       INT             NOT NULL,
    id_sucursal        INT             NOT NULL,
    fecha_compra       DATETIME2(0)    NOT NULL,
    total_compra       DECIMAL(12,2)   NOT NULL,
    numero_factura     VARCHAR(50)     NULL,
    estado             VARCHAR(20)     NOT NULL,
    CONSTRAINT PK_Compras PRIMARY KEY (id_compra),
    CONSTRAINT FK_Compras_Proveedores FOREIGN KEY (id_proveedor) REFERENCES dbo.Proveedores(id_proveedor),
    CONSTRAINT FK_Compras_Sucursales FOREIGN KEY (id_sucursal) REFERENCES dbo.Sucursales(id_sucursal),
    CONSTRAINT CK_Compras_Total CHECK (total_compra > 0),
    CONSTRAINT CK_Compras_Estado CHECK (estado IN ('pendiente','completada','rechazada','anulada'))
);
GO

/* ============================================================
   NIVEL 4 - DETALLES TRANSACCIONALES
   ============================================================ */

CREATE TABLE dbo.DetalleVentas (
    id_detalle          INT             NOT NULL,
    id_venta            INT             NOT NULL,
    id_producto         INT             NOT NULL,
    cantidad             INT             NOT NULL,
    precio_unitario      DECIMAL(10,2)   NOT NULL,
    subtotal             DECIMAL(12,2)   NOT NULL,
    CONSTRAINT PK_DetalleVentas PRIMARY KEY (id_detalle),
    CONSTRAINT FK_DetalleVentas_Ventas FOREIGN KEY (id_venta) REFERENCES dbo.Ventas(id_venta),
    CONSTRAINT FK_DetalleVentas_Productos FOREIGN KEY (id_producto) REFERENCES dbo.Productos(id_producto),
    CONSTRAINT CK_DetalleVentas_Cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_DetalleVentas_Precio CHECK (precio_unitario > 0),
    CONSTRAINT CK_DetalleVentas_Subtotal CHECK (subtotal > 0),
    CONSTRAINT UQ_DetalleVentas_VentaProducto UNIQUE (id_venta, id_producto)
);
GO

CREATE TABLE dbo.DetalleCompras (
    id_detalle_compra   INT             NOT NULL,
    id_compra           INT             NOT NULL,
    id_producto         INT             NOT NULL,
    cantidad             INT             NOT NULL,
    precio_unitario      DECIMAL(10,2)   NOT NULL,
    subtotal             DECIMAL(12,2)   NOT NULL,
    CONSTRAINT PK_DetalleCompras PRIMARY KEY (id_detalle_compra),
    CONSTRAINT FK_DetalleCompras_Compras FOREIGN KEY (id_compra) REFERENCES dbo.Compras(id_compra),
    CONSTRAINT FK_DetalleCompras_Productos FOREIGN KEY (id_producto) REFERENCES dbo.Productos(id_producto),
    CONSTRAINT CK_DetalleCompras_Cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_DetalleCompras_Precio CHECK (precio_unitario > 0),
    CONSTRAINT CK_DetalleCompras_Subtotal CHECK (subtotal > 0)
);
GO

/* ============================================================
   TABLA DE AUDITORIA (esquema audit)
   Aqui escriben los triggers y procedimientos: quien, que tabla,
   que operacion, y cuando. Es la evidencia de trazabilidad que
   pide la Ley N.29733 (articulo 11, medidas de seguridad tecnica).
   ============================================================ */
CREATE TABLE audit.LogAuditoria (
    id_log             BIGINT IDENTITY(1,1) NOT NULL,
    tabla_afectada     SYSNAME         NOT NULL,
    operacion          VARCHAR(15)     NOT NULL,   -- INSERT / UPDATE / DELETE / VALIDACION / ERROR
    usuario_bd         SYSNAME         NOT NULL CONSTRAINT DF_LogAuditoria_Usuario DEFAULT (SUSER_SNAME()),
    fecha_evento       DATETIME2(3)    NOT NULL CONSTRAINT DF_LogAuditoria_Fecha DEFAULT (SYSDATETIME()),
    clave_registro     NVARCHAR(100)   NULL,
    detalle            NVARCHAR(1000)  NULL,
    CONSTRAINT PK_LogAuditoria PRIMARY KEY (id_log)
);
GO

/* ============================================================
   TABLAS DE CUARENTENA (esquema calidad)
   Registros que NO pasaron la validacion al cargar de stg a dbo.
   Se guardan completos (como texto) + el motivo de rechazo, para
   que el equipo pueda revisarlos sin perder informacion.
   ============================================================ */
CREATE TABLE calidad.VentasRechazadas (
    id_rechazo         BIGINT IDENTITY(1,1) NOT NULL,
    id_venta_origen    VARCHAR(50)     NULL,
    motivo_rechazo     NVARCHAR(200)   NOT NULL,
    fecha_carga        DATETIME2(3)    NOT NULL CONSTRAINT DF_VentasRechazadas_Fecha DEFAULT (SYSDATETIME()),
    datos_originales    NVARCHAR(1000)  NULL,
    CONSTRAINT PK_VentasRechazadas PRIMARY KEY (id_rechazo)
);
GO

CREATE TABLE calidad.VentasObservadas (
    id_observacion      BIGINT IDENTITY(1,1) NOT NULL,
    id_venta_origen     VARCHAR(50)     NULL,
    motivo_observacion  NVARCHAR(200)   NOT NULL,
    fecha_carga         DATETIME2(3)    NOT NULL CONSTRAINT DF_VentasObservadas_Fecha DEFAULT (SYSDATETIME()),
    datos_originales    NVARCHAR(1000)  NULL,
    CONSTRAINT PK_VentasObservadas PRIMARY KEY (id_observacion)
);
GO

CREATE TABLE calidad.ClientesObservados (
    id_observacion      BIGINT IDENTITY(1,1) NOT NULL,
    id_cliente_origen   VARCHAR(50)     NULL,
    motivo_observacion  NVARCHAR(200)   NOT NULL,
    fecha_carga         DATETIME2(3)    NOT NULL CONSTRAINT DF_ClientesObservados_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_ClientesObservados PRIMARY KEY (id_observacion)
);
GO

/* Verificacion: deben verse las tablas dbo + 1 audit + 3 tablas de calidad */
SELECT TABLE_SCHEMA AS esquema, TABLE_NAME AS tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('dbo','audit','calidad') AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO
