/* 03 — Seguridad avanzada: 7 roles de base de datos (Capítulo 6). Base: KUSI_MINIMARKET.
   Principio de mínimo privilegio (Ley 29733 arts. 9 y 16; ISO/IEC 27001:2022 A.5.15, A.8.3).
   Los logins usan contraseñas de EJEMPLO: cámbielas; NO las suba al repositorio. */
USE master;
GO
DECLARE @pw NVARCHAR(60) = N'Cambiar#Kusi2026!';   -- AJUSTAR: contraseña temporal (CHECK_POLICY activo)
DECLARE @u TABLE(n SYSNAME);
INSERT @u VALUES (N'lg_cajero'),(N'lg_encargado'),(N'lg_jefecompras'),(N'lg_gerente'),(N'lg_analista'),(N'lg_auditor'),(N'lg_admin');
DECLARE @n SYSNAME, @sql NVARCHAR(MAX);
DECLARE c CURSOR FOR SELECT n FROM @u;
OPEN c; FETCH NEXT FROM c INTO @n;
WHILE @@FETCH_STATUS=0
BEGIN
    IF SUSER_ID(@n) IS NULL
    BEGIN
        SET @sql = N'CREATE LOGIN '+QUOTENAME(@n)+N' WITH PASSWORD='''+@pw+N''', CHECK_POLICY=ON, CHECK_EXPIRATION=ON, DEFAULT_DATABASE=KUSI_MINIMARKET;';
        EXEC(@sql);
    END
    FETCH NEXT FROM c INTO @n;
END
CLOSE c; DEALLOCATE c;
GO
USE KUSI_MINIMARKET;
GO
/* Roles */
DECLARE @r TABLE(n SYSNAME);
INSERT @r VALUES (N'Rol_Cajero'),(N'Rol_EncargadoSucursal'),(N'Rol_JefeCompras'),(N'Rol_GerenteComercial'),(N'Rol_AnalistaBI_ETL'),(N'Rol_Auditor'),(N'Rol_AdministradorBD');
DECLARE @x SYSNAME, @q NVARCHAR(MAX);
DECLARE c2 CURSOR FOR SELECT n FROM @r; 
OPEN c2; 
FETCH NEXT FROM c2 INTO @x;
WHILE @@FETCH_STATUS = 0 
BEGIN
    IF DATABASE_PRINCIPAL_ID(@x) IS NULL 
    BEGIN
        SET @q = N'CREATE ROLE ' + QUOTENAME(@x) + N';';
        EXEC sp_executesql @q;
    END
    FETCH NEXT FROM c2 INTO @x; 
END
CLOSE c2; 
DEALLOCATE c2;
GO
/* Usuarios y membresía */
IF DATABASE_PRINCIPAL_ID('u_cajero') IS NULL CREATE USER u_cajero FOR LOGIN lg_cajero;
IF DATABASE_PRINCIPAL_ID('u_encargado') IS NULL CREATE USER u_encargado FOR LOGIN lg_encargado;
IF DATABASE_PRINCIPAL_ID('u_jefecompras') IS NULL CREATE USER u_jefecompras FOR LOGIN lg_jefecompras;
IF DATABASE_PRINCIPAL_ID('u_gerente') IS NULL CREATE USER u_gerente FOR LOGIN lg_gerente;
IF DATABASE_PRINCIPAL_ID('u_analista') IS NULL CREATE USER u_analista FOR LOGIN lg_analista;
IF DATABASE_PRINCIPAL_ID('u_auditor') IS NULL CREATE USER u_auditor FOR LOGIN lg_auditor;
IF DATABASE_PRINCIPAL_ID('u_admin') IS NULL CREATE USER u_admin FOR LOGIN lg_admin;
ALTER ROLE Rol_Cajero ADD MEMBER u_cajero;
ALTER ROLE Rol_EncargadoSucursal ADD MEMBER u_encargado;
ALTER ROLE Rol_JefeCompras ADD MEMBER u_jefecompras;
ALTER ROLE Rol_GerenteComercial ADD MEMBER u_gerente;
ALTER ROLE Rol_AnalistaBI_ETL ADD MEMBER u_analista;
ALTER ROLE Rol_Auditor ADD MEMBER u_auditor;
ALTER ROLE Rol_AdministradorBD ADD MEMBER u_admin;
GO
/* 1. Cajero: solo registra ventas mediante procedimientos (no toca tablas directamente) */
GRANT EXECUTE ON OBJECT::dbo.sp_RegistrarVenta        TO Rol_Cajero;
GRANT EXECUTE ON OBJECT::dbo.sp_RegistrarDetalleVenta TO Rol_Cajero;
GRANT SELECT  ON OBJECT::dbo.Productos   TO Rol_Cajero;
GRANT SELECT  ON OBJECT::dbo.MetodosPago TO Rol_Cajero;
DENY  DELETE, UPDATE ON SCHEMA::dbo TO Rol_Cajero;
DENY  SELECT ON SCHEMA::audit  TO Rol_Cajero;
DENY  SELECT ON OBJECT::dbo.Clientes TO Rol_Cajero;   -- minimización: no ve DNI ni correo
/* 2. Encargado de sucursal: valida ventas, consulta y ajusta stock vía procedimiento */
GRANT EXECUTE ON OBJECT::dbo.sp_ValidarVenta TO Rol_EncargadoSucursal;
GRANT SELECT ON OBJECT::dbo.Ventas        TO Rol_EncargadoSucursal;
GRANT SELECT ON OBJECT::dbo.DetalleVentas TO Rol_EncargadoSucursal;
GRANT SELECT ON OBJECT::dbo.Productos     TO Rol_EncargadoSucursal;
GRANT SELECT ON OBJECT::dbo.fn_ProductosParaReabastecer TO Rol_EncargadoSucursal;  -- AJUSTAR si la función es TVF/escalar
DENY  DELETE ON SCHEMA::dbo TO Rol_EncargadoSucursal;
DENY  SELECT ON SCHEMA::audit TO Rol_EncargadoSucursal;
/* 3. Jefe de compras: proveedores, compras y productos */
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.Proveedores     TO Rol_JefeCompras;
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.Compras         TO Rol_JefeCompras;
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.DetalleCompras  TO Rol_JefeCompras;
GRANT SELECT ON OBJECT::dbo.Productos TO Rol_JefeCompras;
DENY  SELECT ON OBJECT::dbo.Clientes TO Rol_JefeCompras;
DENY  SELECT, INSERT, UPDATE, DELETE ON SCHEMA::audit TO Rol_JefeCompras;
/* 4. Gerente comercial: lectura de ventas y estructura de promociones; sin datos personales */
GRANT SELECT ON OBJECT::dbo.Ventas        TO Rol_GerenteComercial;
GRANT SELECT ON OBJECT::dbo.DetalleVentas TO Rol_GerenteComercial;
GRANT SELECT ON OBJECT::dbo.Productos     TO Rol_GerenteComercial;
GRANT SELECT ON OBJECT::dbo.Sucursales    TO Rol_GerenteComercial;
GRANT EXECUTE ON OBJECT::dbo.sp_EvaluarExpansionSucursal TO Rol_GerenteComercial;
GRANT EXECUTE ON OBJECT::dbo.sp_EfectividadPromocion     TO Rol_GerenteComercial;
DENY  SELECT ON OBJECT::dbo.Clientes TO Rol_GerenteComercial;
DENY  INSERT, UPDATE, DELETE ON SCHEMA::dbo TO Rol_GerenteComercial;
/* 5. Analista BI/ETL: lectura (OLTP ya depurado y calidad); NO modifica el OLTP */
GRANT SELECT ON SCHEMA::dbo    TO Rol_AnalistaBI_ETL;
GRANT SELECT ON SCHEMA::calidad TO Rol_AnalistaBI_ETL;
DENY  INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO Rol_AnalistaBI_ETL;
DENY  SELECT ON OBJECT::dbo.Clientes TO Rol_AnalistaBI_ETL;   -- el DW usa distrito/clasificación, no DNI/correo
/* 6. Auditor: solo auditoría y calidad; sin acceso al esquema operacional */
GRANT SELECT ON SCHEMA::audit   TO Rol_Auditor;
GRANT SELECT ON SCHEMA::calidad TO Rol_Auditor;
DENY  SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO Rol_Auditor;
DENY  INSERT, UPDATE, DELETE ON SCHEMA::audit TO Rol_Auditor;   -- el auditor no altera su propia evidencia
/* 7. Administrador BD: control de la base (sin ser sysadmin del servidor) */
ALTER ROLE db_owner ADD MEMBER Rol_AdministradorBD;
GO
/* Rol de ETL sobre el DW: ejecute este bloque en KUSI_DW (script 03b al final de este archivo) */
SELECT r.name AS rol, m.name AS miembro
FROM sys.database_role_members rm JOIN sys.database_principals r ON r.principal_id=rm.role_principal_id
JOIN sys.database_principals m ON m.principal_id=rm.member_principal_id
WHERE r.name LIKE 'Rol[_]%' ORDER BY r.name;   -- CAPTURA Figura 7(a): roles y miembros
GO
/* ---------- PRUEBAS DE ACCESO (CAPTURA Figura 7(b)) ----------
   Cada línea debe terminar en ERROR 229/230 (permiso denegado) salvo las marcadas OK. */
EXECUTE AS USER='u_analista';  SELECT TOP 1 id_venta FROM dbo.Ventas;          -- OK (lectura)
BEGIN TRY UPDATE dbo.Ventas SET estado=estado WHERE id_venta=100; END TRY BEGIN CATCH SELECT 'analista UPDATE -> '+ERROR_MESSAGE() AS resultado; END CATCH;
REVERT;
EXECUTE AS USER='u_auditor';   SELECT TOP 1 * FROM audit.LogAuditoria;         -- OK
BEGIN TRY SELECT TOP 1 * FROM dbo.Ventas; END TRY BEGIN CATCH SELECT 'auditor SELECT dbo.Ventas -> '+ERROR_MESSAGE() AS resultado; END CATCH;
REVERT;
EXECUTE AS USER='u_cajero';
BEGIN TRY SELECT TOP 1 * FROM dbo.Clientes; END TRY BEGIN CATCH SELECT 'cajero SELECT Clientes -> '+ERROR_MESSAGE() AS resultado; END CATCH;
BEGIN TRY SELECT TOP 1 * FROM audit.LogAuditoria; END TRY BEGIN CATCH SELECT 'cajero SELECT audit -> '+ERROR_MESSAGE() AS resultado; END CATCH;
REVERT;
EXECUTE AS USER='u_gerente';
BEGIN TRY DELETE FROM dbo.Ventas WHERE id_venta=-1; END TRY BEGIN CATCH SELECT 'gerente DELETE -> '+ERROR_MESSAGE() AS resultado; END CATCH;
REVERT;
GO
/* ---------- 03b. En KUSI_DW ---------- */
-- USE KUSI_DW;
-- CREATE ROLE Rol_AnalistaBI_ETL;  CREATE USER u_analista_dw FOR LOGIN lg_analista;
-- ALTER ROLE Rol_AnalistaBI_ETL ADD MEMBER u_analista_dw;
-- GRANT SELECT ON SCHEMA::dw TO Rol_AnalistaBI_ETL;
-- GRANT INSERT, DELETE, UPDATE ON SCHEMA::dw TO Rol_AnalistaBI_ETL;   -- necesario para que el ETL cargue
