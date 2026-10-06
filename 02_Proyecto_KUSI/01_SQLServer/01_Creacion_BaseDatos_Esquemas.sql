/* ================================================================
   KUSI MINIMARKET — SCRIPT 01
   Base de datos y separación de responsabilidades
   ================================================================

   Este primer paso deja preparada la base donde trabajará todo el
   proyecto. No carga datos todavía.

   - stg      : recibe los CSV tal como llegan.
   - calidad  : conserva registros o incidencias que no deben pasar
                al modelo operacional.
   - audit    : registra acciones relevantes para trazabilidad.
   - dbo      : contiene los datos operacionales validados.

   La separación evita mezclar datos crudos con datos de negocio y
   hace más sencillo demostrar qué ocurrió durante una carga.
*/

IF DB_ID(N'KUSI_MINIMARKET') IS NULL
    CREATE DATABASE KUSI_MINIMARKET;
GO

USE KUSI_MINIMARKET;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'stg')
    EXEC(N'CREATE SCHEMA stg');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'calidad')
    EXEC(N'CREATE SCHEMA calidad');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'audit')
    EXEC(N'CREATE SCHEMA audit');
GO

SELECT DB_NAME() AS BaseDatosActual, name AS Esquema
FROM sys.schemas
WHERE name IN (N'dbo', N'stg', N'calidad', N'audit')
ORDER BY name;
GO
