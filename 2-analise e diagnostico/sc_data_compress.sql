--https://desktop.arcgis.com/en/arcmap/latest/extensions/data-reviewer-guide/admin-dr-sql-server/using-data-compression-for-the-reviewer-workspace-in-sql-server.htm#ESRI_SECTION1_08D273ED486C47838748506E31A9D2E9

-- examples
USE REVDB;
GO
EXEC sp_estimate_data_compression_savings 'rev', 'TableA', NULL, NULL,
'ROW';
GO

USE REVDB;
GO
EXEC sp_estimate_data_compression_savings 'rev', 'TableA', NULL, NULL,
'PAGE';
GO

--- estimate in all objects
--https://www.sqlservercentral.com/scripts/estimate-compression-for-all-tables-and-indexes-with-both-row-and-page

--------------------------------------------



--Verify REV Schema Storage
USE [revdb]
GO
--List all tables
SELECT USER_NAME(o.uid) [owner], o.name,o.id,o.type,o.status
FROM sysobjects o
WHERE USER_NAME(o.uid) = 'rev'
AND o.type <> 'S' and o.type = 'U'
ORDER BY o.name,o.type;
GO
--List all indexes
SELECT USER_NAME(o.uid) [owner], OBJECT_NAME(i.id) [table], i.name [index],o.type [type]
FROM sysindexes i inner join sysobjects o ON i.id = o.id
WHERE USER_NAME(o.uid) = 'rev'
AND o.type <> 'S' and o.type = 'U' and i.indid = 1
ORDER BY USER_NAME(o.uid),OBJECT_NAME(i.id),i.name;
GO
--Table page compression
--Example:
ALTER TABLE REVDB.REVTABLELINE 
REBUILD WITH (DATA_COMPRESSION = PAGE);
GO
--Generate script to set table page compression:
SELECT 'ALTER TABLE ' + USER_NAME(o.uid) + '.' + o.name + ' REBUILD WITH (DATA_COMPRESSION = PAGE);' [TXTSQL]
FROM sysobjects o
WHERE USER_NAME(o.uid) = 'rev'
AND o.type <> 'S' and o.type = 'U'
ORDER BY o.name,o.type;
GO
--Index page compression
--Example:
ALTER INDEX R125_pk 
ON REVDB.REVTABLELINE
REBUILD WITH ( DATA_COMPRESSION = PAGE ) ;
GO
--Generate script to set index page compression:
SELECT 'ALTER INDEX ' + i.name + ' ON ' + USER_NAME(o.uid) + '.' + OBJECT_NAME(i.id) + ' REBUILD WITH ( DATA_COMPRESSION = PAGE );' [TXTSQL] 
FROM sysindexes i inner join sysobjects o ON i.id = o.id WHERE USER_NAME(o.uid) = 'rev' 
AND i.name NOT LIKE '_WA%'
--AND o.type <> 'S' and o.type = 'U' and i.indid = 1 
ORDER BY USER_NAME(o.uid),OBJECT_NAME(i.id),i.name; GO

