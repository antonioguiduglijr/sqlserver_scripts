--http://www.dirceuresende.com/blog/monitorar-operacoes-de-ddl-e-dcl-utilizando-a-fn_trace_gettable-do-sql-server/
--Monitorando operações de DDL e DCL utilizando a fn_trace_gettable

/***************************************************************************
--https://blogs.technet.microsoft.com/beatrice/2008/04/29/sql-server-default-trace/

-- eventos
DECLARE @id INT = ( SELECT id FROM sys.traces WHERE is_default = 1 )
SELECT DISTINCT
       eventid,
       name
FROM fn_trace_geteventinfo(@id) A
JOIN sys.trace_events B ON A.eventid = B.trace_event_id

-- colunas
SELECT t.EventID, t.ColumnID, e.name as Event_Description, c.name as Column_Description
  FROM ::fn_trace_geteventinfo(1) t
  JOIN sys.trace_events e ON t.eventID = e.trace_event_id
  JOIN sys.trace_columns c ON t.columnid = c.trace_column_id
 WHERE EventID = 164

-- EventSubClass -> 0=Begin 1=Commit 2=Rollback

***************************************************************************/

USE [ofc2principal]
GO

DECLARE @Ds_Arquivo_Trace VARCHAR(255) = (SELECT SUBSTRING([path], 0, LEN([path])-CHARINDEX('\', REVERSE([path]))+1) + '\Log.trc' FROM sys.traces WHERE is_default = 1)

SELECT A.HostName,
       A.ApplicationName,
       A.NTUserName,
       A.NTDomainName,
       A.LoginName,
       A.SPID,
       A.EventClass,
       B.Name,
       A.EventSubClass,
       A.TextData,
       A.StartTime,
       A.ObjectName,
       A.DatabaseName,
       A.TargetLoginName,
       A.TargetUserName--, C.*
  FROM [fn_trace_gettable](@Ds_Arquivo_Trace, DEFAULT) A
  JOIN master.sys.trace_events                         B ON A.EventClass = B.trace_event_id
--  JOIN master.sys.trace_categories                     C ON C.Category_id = B.Category_id
 WHERE A.EventClass IN ( 164, 46, 47, 108, 110, 152 ) 
   AND A.StartTime >= GETDATE()-30
   AND A.LoginName NOT IN ( 'NT AUTHORITY\NETWORK SERVICE' )
   AND A.DatabaseName <> 'tempdb'
   AND NOT (B.name LIKE 'Object:%' AND A.ObjectName IS NULL )
AND A.ObjectName = 'PRI_SP_LISTARBLOCOEMAILENVIO'
   AND NOT (A.ApplicationName LIKE 'Red Gate%' OR A.ApplicationName LIKE '%Intellisense%' OR A.ApplicationName = 'DacFx Deploy')
 ORDER BY StartTime DESC
GO

