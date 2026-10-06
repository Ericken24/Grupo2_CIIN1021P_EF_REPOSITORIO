/* 07 - Benchmark SQL Server (Capítulo 10): facturación por sucursal y mes (JOIN + GROUP BY).
   Escalas x1, x5 y x10 del hecho. Ejecutar TODO junto en SSMS (Ctrl+A, F5).
   Resultados: pestaña "Mensajes" (Execution Times, Figura 16b) y pestaña "Resultados" (Tabla 33). */
USE KUSI_DW;
GO
SET NOCOUNT ON;

DECLARE @sch SYSNAME = (SELECT TOP 1 s.name
                        FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
                        WHERE t.name = 'FactVentas');
IF @sch IS NULL THROW 50001, 'No se encontró la tabla FactVentas en KUSI_DW.', 1;

DECLARE @res TABLE (escala INT, corrida INT, ms INT, filas BIGINT);
DECLARE @i INT = 1, @run INT, @esc INT, @src NVARCHAR(300), @sql NVARCHAR(MAX),
        @t0 DATETIME2, @n BIGINT, @fecha NVARCHAR(300);

SET @fecha = QUOTENAME(@sch) + N'.DimFecha';

/* 1) Crear las tablas replicadas x5 y x10 */
WHILE @i <= 3
BEGIN
    SET @esc = CHOOSE(@i, 1, 5, 10);
    IF @esc > 1
    BEGIN
        SET @src = QUOTENAME(@sch) + N'.' + QUOTENAME(N'FactVentas_x' + CAST(@esc AS NVARCHAR(5)));
        SET @sql = N'IF OBJECT_ID(''' + @src + N''') IS NOT NULL DROP TABLE ' + @src + N';';
        EXEC (@sql);
        SET @sql = N'SELECT f.* INTO ' + @src + N' FROM ' + QUOTENAME(@sch) + N'.FactVentas f '
                 + N'CROSS JOIN (SELECT TOP (' + CAST(@esc AS NVARCHAR(5)) + N') 1 AS n FROM sys.all_objects) r;';
        EXEC (@sql);
    END
    SET @i += 1;
END

/* 2) Medir: 4 corridas por escala (la 1.ª calienta caché y se descarta) */
SET STATISTICS TIME ON;
SET @i = 1;
WHILE @i <= 3
BEGIN
    SET @esc = CHOOSE(@i, 1, 5, 10);
    IF @esc = 1
        SET @src = QUOTENAME(@sch) + N'.FactVentas';
    ELSE
        SET @src = QUOTENAME(@sch) + N'.' + QUOTENAME(N'FactVentas_x' + CAST(@esc AS NVARCHAR(5)));

    SET @sql = N'SELECT @n = COUNT_BIG(*) FROM ' + @src + N';';
    EXEC sp_executesql @sql, N'@n BIGINT OUTPUT', @n = @n OUTPUT;

    SET @sql = N'SELECT f.KeySucursal, d.Anio, d.Mes, SUM(f.VentaNeta) AS v INTO #r '
             + N'FROM ' + @src + N' f JOIN ' + @fecha + N' d ON d.KeyFecha = f.KeyFecha '
             + N'GROUP BY f.KeySucursal, d.Anio, d.Mes;';
    SET @run = 1;
    WHILE @run <= 4
    BEGIN
        SET @t0 = SYSDATETIME();
        EXEC (@sql);
        INSERT @res VALUES (@esc, @run, DATEDIFF_BIG(MILLISECOND, @t0, SYSDATETIME()), @n);
        SET @run += 1;
    END
    SET @i += 1;
END
SET STATISTICS TIME OFF;

/* 3) Mediana por escala (corridas 2 a 4) para la Tabla 33 */
SELECT DISTINCT escala AS Escala, filas AS Filas_hecho,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ms) OVER (PARTITION BY escala) AS Mediana_ms,
       CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ms) OVER (PARTITION BY escala) / 1000.0
            AS DECIMAL(10,3)) AS Mediana_seg
FROM @res WHERE corrida >= 2
ORDER BY Escala;
GO

/* LIMPIEZA al terminar (libera espacio); cambie dbo si FactVentas está en otro esquema: */
--DROP TABLE dw.FactVentas_x5; DROP TABLE dw.FactVentas_x10;