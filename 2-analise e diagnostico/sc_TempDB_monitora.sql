--https://www.fabriciolima.net/blog/2020/08/19/monitoramento-no-sql-server-o-que-fazer-quando-receber-um-alerta-de-crescimento-do-tempdb/

-- Analise de TempDB
-- 2021-08-18


select *
from Traces..Alert_Parameter
where Nm_Alert = 'Tempdb MDF File Utilization'


-- Analisar a utilização do tempdb
USE tempdb;
SELECT a.name AS LogicalName,
'SizeinMB' = (size/128)
,fileproperty(a.name, 'spaceused' )/128 as UsedinMB
,(size/128) -fileproperty (a.name,'SpaceUsed')/128 AS FreeInMB
,'Free%'=cast (((a.size/128.0)-fileproperty(a.name,'SpaceUsed')/128.0)/(a.size/128.0)*100 as numeric(15))
, ((a.size/128.0)-fileproperty(a.name,'SpaceUsed')/128.0) / SUM ((a.size/128.0)-(fileproperty(a.name,'SpaceUsed')/128)) OVER (PARTITION BY fg.data_space_id) As [PropFree%]
,fg.name
FROM sysfiles a LEFT join sys.filegroups fg 
ON a.groupid = fg.data_space_id



update Traces..Alert_Parameter
set Vl_Parameter_2 = 4000  --default é 10000 MB
where Nm_Alert = 'Tempdb MDF File Utilization'

USE master;
sp_whoisactive


--Query que pode ajudar a pegar o que está no tempdb
USE tempdb;
;with tab(session_id, host_name, login_name, total_alocado_mb, text)
as(
SELECT a.session_id,
b.host_name,
b.login_name,
( user_objects_alloc_page_count + internal_objects_alloc_page_count ) * 1.0 / 128 AS total_alocado_mb,
d.TEXT
FROM sys.dm_db_session_space_usage a
JOIN sys.dm_exec_sessions b ON a.session_id = b.session_id
JOIN sys.dm_exec_connections c ON c.session_id = b.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS d
WHERE a.session_id > 50 AND a.session_id <> @@SPID
--AND ( user_objects_alloc_page_count + internal_objects_alloc_page_count ) * 1.0 / 128 > 10 -- Ocupam mais de 10 MB
)
select top 20 * from tab order by 4 desc


USE tempdb;
SELECT a.name AS LogicalName,
'SizeinMB' = (size/128)
,fileproperty(a.name, 'spaceused' )/128 as UsedinMB
,(size/128) -fileproperty (a.name,'SpaceUsed')/128 AS FreeInMB
,'Free%'=cast (((a.size/128.0)-fileproperty(a.name,'SpaceUsed')/128.0)/(a.size/128.0)*100 as numeric(15))
, ((a.size/128.0)-fileproperty(a.name,'SpaceUsed')/128.0) / SUM ((a.size/128.0)-(fileproperty(a.name,'SpaceUsed')/128)) OVER (PARTITION BY fg.data_space_id) As [PropFree%]
,fg.name
FROM sysfiles a LEFT join sys.filegroups fg 
ON a.groupid = fg.data_space_id


--kill 66
--kill 65



----- rquivo para testar a carga no TEMPDB
--drop table #StressTempDB

 SELECT TOP 1000000000
        IDENTITY(INT,1,1) AS RowNum
   INTO #StressTempDB
   FROM master.sys.all_columns ac1,
        master.sys.all_columns ac2,
        master.sys.all_columns ac3;
GO