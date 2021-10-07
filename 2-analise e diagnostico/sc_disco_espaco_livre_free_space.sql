/** 
script para retornar espaço utilizado/livre numa instancia 
28/03/2014 - criacao
28/07/2016 - usando a sys.dm_os_volume_stats - http://tomaslind.net/2014/01/28/alternative-xp_fixeddrives/
**/

SELECT DISTINCT
       SUBSTRING(volume_mount_point, 1, 1) AS volume_mount_point,
       ( total_bytes/1024/1024 ) AS total_MB,
       ( available_bytes/1024/1024 ) AS available_MB,
       CONVERT(NUMERIC(10,2), (( available_bytes/1024.0 ) / ( total_bytes/1024.0 ))*100 ) AS free_pct
  FROM sys.master_files AS f
 CROSS 
 APPLY sys.dm_os_volume_stats(f.database_id, f.file_id)
 ORDER BY 1;



/**************************************** ANTIGO -- 28/07/2016
IF EXISTS (SELECT OBJECT_ID('tempdb..#usado_databases'))
    DROP TABLE #usado_databases

SELECT UPPER(left(physical_name,1)) as drive, sum((size*8)/1024) as mb_utilizado_instancia
  INTO #usado_databases
  FROM sys.master_files
 GROUP BY left(physical_name,1)
 ORDER BY 1

IF EXISTS (SELECT OBJECT_ID('tempdb..#TMP_DRIVES'))
    DROP TABLE #TMP_DRIVES
 
CREATE TABLE #TMP_DRIVES
    (   DRIVE CHAR(1) NOT NULL,
        MBFREE INT NOT NULL  )
 
INSERT INTO #TMP_DRIVES
EXEC xp_fixeddrives

SELECT u.drive AS Drive, 
       mbfree/1024 AS Free_GB
  FROM #usado_databases u
  LEFT
  JOIN #TMP_DRIVES      d ON d.drive = u.drive

********************************************************************************************************/
