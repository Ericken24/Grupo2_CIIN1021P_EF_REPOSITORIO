/* ================================================================
   KUSI MINIMARKET — DATA WAREHOUSE
   Modelo dimensional estrella — enfoque Kimball
   ================================================================

   El grano de FactVentas es: una fila por producto dentro de una
   venta. Esto permite agregar después por fecha, sucursal, producto,
   cliente, empleado o método de pago sin perder el nivel de detalle.
*/
IF DB_ID(N'KUSI_DW') IS NULL CREATE DATABASE KUSI_DW;
GO
USE KUSI_DW;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'dw') EXEC(N'CREATE SCHEMA dw');
GO

CREATE TABLE dw.DimFecha(
    KeyFecha INT NOT NULL,Fecha DATE NOT NULL,Anio SMALLINT NOT NULL,Mes TINYINT NOT NULL,
    NombreMes NVARCHAR(20) NOT NULL,Trimestre TINYINT NOT NULL,DiaSemana TINYINT NOT NULL,
    NombreDia NVARCHAR(20) NOT NULL,EsFinDeSemana BIT NOT NULL,EsFeriado BIT NOT NULL DEFAULT(0),
    CONSTRAINT PK_DimFecha PRIMARY KEY(KeyFecha),CONSTRAINT UQ_DimFecha_Fecha UNIQUE(Fecha),
    CONSTRAINT CK_DimFecha_DiaSemana CHECK(DiaSemana BETWEEN 1 AND 7)
);
GO

CREATE TABLE dw.DimSucursal(
    KeySucursal INT NOT NULL,NombreSucursal NVARCHAR(150) NOT NULL,Distrito NVARCHAR(100) NULL,
    TipoLocal NVARCHAR(50) NULL,EsOperativa BIT NOT NULL,FechaApertura DATE NULL,
    CONSTRAINT PK_DimSucursal PRIMARY KEY(KeySucursal)
);
GO

CREATE TABLE dw.DimProducto(
    KeyProducto INT NOT NULL,CodigoBarras VARCHAR(50) NULL,NombreProducto NVARCHAR(250) NOT NULL,
    Categoria NVARCHAR(100) NOT NULL,Proveedor NVARCHAR(200) NOT NULL,PrecioVentaActual DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_DimProducto PRIMARY KEY(KeyProducto)
);
GO

CREATE TABLE dw.DimCliente(
    KeyCliente INT NOT NULL,Distrito NVARCHAR(100) NULL,ClasificacionCliente VARCHAR(20) NULL,
    ClienteAnonimo BIT NOT NULL,Consentimiento BIT NULL,
    CONSTRAINT PK_DimCliente PRIMARY KEY(KeyCliente)
);
GO

CREATE TABLE dw.DimMetodoPago(
    KeyMetodoPago INT NOT NULL,NombreMetodo NVARCHAR(100) NOT NULL,Tipo NVARCHAR(50) NULL,
    CONSTRAINT PK_DimMetodoPago PRIMARY KEY(KeyMetodoPago)
);
GO

CREATE TABLE dw.DimEmpleado(
    KeyEmpleado INT NOT NULL,NombreCompleto NVARCHAR(200) NOT NULL,Cargo NVARCHAR(100) NULL,Sucursal NVARCHAR(150) NULL,
    CONSTRAINT PK_DimEmpleado PRIMARY KEY(KeyEmpleado)
);
GO

CREATE TABLE dw.FactVentas(
    KeyVenta BIGINT IDENTITY(1,1) NOT NULL,KeyFecha INT NOT NULL,KeySucursal INT NOT NULL,KeyProducto INT NOT NULL,
    KeyCliente INT NOT NULL,KeyMetodoPago INT NOT NULL,KeyEmpleado INT NOT NULL,IdVentaOrigen INT NOT NULL,
    IdDetalleOrigen INT NOT NULL,Cantidad INT NOT NULL,PrecioUnitario DECIMAL(10,2) NOT NULL,VentaNeta DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_FactVentas PRIMARY KEY(KeyVenta),
    CONSTRAINT FK_FactVentas_Fecha FOREIGN KEY(KeyFecha) REFERENCES dw.DimFecha(KeyFecha),
    CONSTRAINT FK_FactVentas_Sucursal FOREIGN KEY(KeySucursal) REFERENCES dw.DimSucursal(KeySucursal),
    CONSTRAINT FK_FactVentas_Producto FOREIGN KEY(KeyProducto) REFERENCES dw.DimProducto(KeyProducto),
    CONSTRAINT FK_FactVentas_Cliente FOREIGN KEY(KeyCliente) REFERENCES dw.DimCliente(KeyCliente),
    CONSTRAINT FK_FactVentas_MetodoPago FOREIGN KEY(KeyMetodoPago) REFERENCES dw.DimMetodoPago(KeyMetodoPago),
    CONSTRAINT FK_FactVentas_Empleado FOREIGN KEY(KeyEmpleado) REFERENCES dw.DimEmpleado(KeyEmpleado),
    CONSTRAINT CK_FactVentas_Cantidad CHECK(Cantidad>0),CONSTRAINT CK_FactVentas_VentaNeta CHECK(VentaNeta>0)
);
GO
CREATE INDEX IX_FactVentas_FechaSucursal ON dw.FactVentas(KeyFecha,KeySucursal);
CREATE INDEX IX_FactVentas_Producto ON dw.FactVentas(KeyProducto);
GO

CREATE TABLE dw.LogETL(
    id_log INT IDENTITY(1,1) NOT NULL,fecha_ejecucion DATETIME2(3) NOT NULL DEFAULT(SYSDATETIME()),
    origen NVARCHAR(100) NOT NULL,filas_leidas INT NOT NULL,filas_aceptadas INT NOT NULL,
    filas_rechazadas INT NOT NULL,motivo_rechazo NVARCHAR(500) NULL,
    CONSTRAINT PK_LogETL PRIMARY KEY(id_log)
);
GO

SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dw' ORDER BY TABLE_NAME;
GO
