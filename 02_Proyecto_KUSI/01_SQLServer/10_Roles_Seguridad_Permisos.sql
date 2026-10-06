/* ================================================================
   KUSI MINIMARKET — SCRIPT 10
   Roles, privilegios y segregación de funciones
   ================================================================

   Se separan tres responsabilidades:
   - administrador: opera y mantiene la base.
   - analista: consulta datos para análisis, sin modificar OLTP.
   - auditor: revisa trazabilidad y calidad, sin acceso directo a dbo.

   No se incluyen contraseñas en este archivo. Las credenciales son
   datos de configuración y deben crearse fuera del repositorio o con
   el mecanismo seguro de la instalación.
*/
USE KUSI_MINIMARKET;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='rol_administrador' AND type='R') CREATE ROLE rol_administrador;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='rol_analista' AND type='R') CREATE ROLE rol_analista;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='rol_auditor' AND type='R') CREATE ROLE rol_auditor;
GO

/* Administrador: puede operar el esquema dbo y revisar auditoría/calidad. */
GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON SCHEMA::dbo TO rol_administrador;
GRANT SELECT ON SCHEMA::audit TO rol_administrador;
GRANT SELECT ON SCHEMA::calidad TO rol_administrador;
GO

/* Analista: lectura solamente. La modificación queda explícitamente negada. */
GRANT SELECT ON SCHEMA::dbo TO rol_analista;
DENY INSERT,UPDATE,DELETE,EXECUTE ON SCHEMA::dbo TO rol_analista;
GO

/* Auditor: consulta evidencia de auditoría/calidad sin consultar el OLTP. */
GRANT SELECT ON SCHEMA::audit TO rol_auditor;
GRANT SELECT ON SCHEMA::calidad TO rol_auditor;
DENY SELECT,INSERT,UPDATE,DELETE,EXECUTE ON SCHEMA::dbo TO rol_auditor;
GO

/* Verificación de privilegios por rol. Esta consulta es una evidencia
   directa de la segregación implementada. */
SELECT dp.name AS rol,p.permission_name,p.state_desc,p.class_desc
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp ON dp.principal_id=p.grantee_principal_id
WHERE dp.name IN('rol_administrador','rol_analista','rol_auditor')
ORDER BY dp.name,p.permission_name;
GO

/* Prueba de pertenencia de usuarios. La creación de logins reales se
   hace de forma segura y separada. Ejemplo:

   CREATE LOGIN [login_analista_km] WITH PASSWORD = '...';
   USE KUSI_MINIMARKET;
   CREATE USER [usr_analista_km] FOR LOGIN [login_analista_km];
   ALTER ROLE rol_analista ADD MEMBER [usr_analista_km];

   seún investigaciones sobre la protección de datos, es recomendable
   que cuando subimos los scripts a algún repositorio  no se debe mostrar los
   usuarios ni las contraseñas, pero en este aparatado esta el ejemplo
   de como se hace para crear un usuario y asignarle su contraseña.
*/
