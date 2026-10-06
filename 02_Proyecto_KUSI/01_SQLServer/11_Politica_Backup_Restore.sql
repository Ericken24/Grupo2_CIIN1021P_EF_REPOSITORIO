/* ================================================================
   KUSI MINIMARKET — SCRIPT 11
   Política de respaldo y prueba de restauración
   ================================================================

   Política propuesta para el escenario académico:
   - FULL semanal.
   - DIFFERENTIAL diario.
   - Restauración de prueba a una base con nombre diferente.

   Antes de ejecutar, crear la carpeta indicada y verificar que la
   cuenta del servicio de SQL Server tenga permiso de escritura.
*/
USE master;
GO

/* 1. FULL semanal. */
BACKUP DATABASE KUSI_MINIMARKET
TO DISK='C:\KUSI_MINIMARKET\Backups\KUSI_MINIMARKET_FULL.bak'
WITH INIT,CHECKSUM,STATS=10,
NAME='KUSI_MINIMARKET_FULL_SEMANAL';
GO

/* 2. DIFFERENTIAL diario. */
BACKUP DATABASE KUSI_MINIMARKET
TO DISK='C:\KUSI_MINIMARKET\Backups\KUSI_MINIMARKET_DIFF.bak'
WITH DIFFERENTIAL,INIT,CHECKSUM,STATS=10,
NAME='KUSI_MINIMARKET_DIFF_DIARIO';
GO

/* 3. Comprobación física del backup. */
RESTORE VERIFYONLY
FROM DISK='C:\KUSI_MINIMARKET\Backups\KUSI_MINIMARKET_FULL.bak'
WITH CHECKSUM;
GO

/* 4. Obtener nombres lógicos antes de RESTORE DATABASE. Ejecutar y
      usar exactamente los valores devueltos en MOVE. */
RESTORE FILELISTONLY
FROM DISK='C:\KUSI_MINIMARKET\Backups\KUSI_MINIMARKET_FULL.bak';
GO

/* 5. Restauración de prueba.
   Si ya existe la base de prueba, eliminarla de forma controlada antes
   de repetir el ensayo. Los nombres lógicos se esperan como los creados
   por el script de la base; si SQL Server devuelve otros, sustituirlos. */
IF DB_ID('KUSI_MINIMARKET_RESTAURADA') IS NOT NULL
BEGIN
    ALTER DATABASE KUSI_MINIMARKET_RESTAURADA SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE KUSI_MINIMARKET_RESTAURADA;
END;
GO

RESTORE DATABASE KUSI_MINIMARKET_RESTAURADA
FROM DISK='C:\KUSI_MINIMARKET\Backups\KUSI_MINIMARKET_FULL.bak'
WITH MOVE 'KUSI_MINIMARKET' TO 'C:\KUSI_MINIMARKET\Backups\KUSI_MINIMARKET_RESTAURADA.mdf',
     MOVE 'KUSI_MINIMARKET_log' TO 'C:\KUSI_MINIMARKET\Backups\KUSI_MINIMARKET_RESTAURADA.ldf',
     NORECOVERY,REPLACE,STATS=10;
GO

RESTORE DATABASE KUSI_MINIMARKET_RESTAURADA
FROM DISK='C:\KUSI_MINIMARKET\Backups\KUSI_MINIMARKET_DIFF.bak'
WITH RECOVERY,STATS=10;
GO

/* 6. Evidencia del restore: estado y conteo. */
SELECT name,state_desc,recovery_model_desc
FROM sys.databases
WHERE name IN('KUSI_MINIMARKET','KUSI_MINIMARKET_RESTAURADA');

SELECT 'Original' AS origen,COUNT(*) AS ventas FROM KUSI_MINIMARKET.dbo.Ventas
UNION ALL
SELECT 'Restaurada',COUNT(*) FROM KUSI_MINIMARKET_RESTAURADA.dbo.Ventas;
GO

/* El resultado real de esta consulta debe guardarse como captura de
   evidencia. No colocar números de ejemplo en el informe. */
