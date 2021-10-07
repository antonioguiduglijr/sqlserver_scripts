--https://www.dirceuresende.com/blog/utilizando-o-trace-padrao-do-sql-server-para-auditar-eventos-fn_trace_gettable/

/****
Utilizando o trace padrão do SQL Server para auditar eventos (fn_trace_gettable)
21/02/2017

DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)
SELECT *
  FROM sys.fn_trace_gettable(@path, DEFAULT)
 WHERE EventClass IN ( 20 )
 ORDER BY StartTime DESC

***/

-- Listando os traces ativos na instância
SELECT * FROM sys.traces


-- Identificando o trace padrão
SELECT * FROM sys.traces WHERE is_default = 1


-- Listando os eventos do trace padrão
DECLARE @id INT = ( SELECT id FROM sys.traces WHERE is_default = 1 )
SELECT DISTINCT
    eventid,
    name
FROM
    fn_trace_geteventinfo(@id) EI
    JOIN sys.trace_events TE ON EI.eventid = TE.trace_event_id 


-- Ativando o Trace Padrão (Já vem habilitado após a instalação)
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'default trace enabled', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'show advanced options', 0;
GO
RECONFIGURE;
GO


-- Desativando o Trace Padrão
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'default trace enabled', 0;
GO
RECONFIGURE;
GO
EXEC sp_configure 'show advanced options', 0;
GO
RECONFIGURE;
GO


-- Identificando os eventos
DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)

SELECT
    B.trace_event_id,
    B.name AS EventName,
    A.DatabaseName,
    A.ApplicationName,
    A.LoginName,
    COUNT(*) AS Quantity
FROM
    dbo.fn_trace_gettable(@path, DEFAULT) A
    INNER JOIN sys.trace_events B ON A.EventClass = B.trace_event_id
GROUP BY
    B.trace_event_id,
    B.name,
    A.DatabaseName,
    A.ApplicationName,
    A.LoginName
ORDER BY
    B.name,
    A.DatabaseName,
    A.ApplicationName,
    A.LoginName


-- Identificando os eventos de Autogrowth
DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)

SELECT
    DatabaseName,
    [FileName],
    CASE EventClass
      WHEN 92 THEN 'Data File Auto Grow'
      WHEN 93 THEN 'Log File Auto Grow'
    END AS EventClass,
    Duration,
    StartTime,
    EndTime,
    SPID,
    ApplicationName,
    LoginName
FROM
    sys.fn_trace_gettable(@path, DEFAULT)
WHERE
    EventClass IN ( 92, 93 )
ORDER BY
    StartTime DESC


-- Identificando eventos de Shrink de Disco
DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)

SELECT
    TextData,
    Duration,
    StartTime,
    EndTime,
    SPID,
    ApplicationName,
    LoginName
FROM
    sys.fn_trace_gettable(@path, DEFAULT)
WHERE
    EventClass IN ( 116 ) AND TextData LIKE 'DBCC%SHRINK%'
ORDER BY
    StartTime DESC


-- Identificando quando comandos DBCC foram executados na instância
DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)

SELECT
    TextData,
    Duration,
    StartTime,
    EndTime,
    SPID,
    ApplicationName,
    LoginName
FROM
    sys.fn_trace_gettable(@path, DEFAULT)
WHERE
    EventClass IN ( 116 )
ORDER BY
    StartTime DESC


-- Identificando quando os backups foram realizados
DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)

SELECT
    DatabaseName,
    TextData,
    Duration,
    StartTime,
    EndTime,
    SPID,
    ApplicationName,
    LoginName
FROM
    sys.fn_trace_gettable(@path, DEFAULT)
WHERE
    EventClass IN ( 115 ) 
    AND EventSubClass = 1
ORDER BY
    StartTime DESC


-- Identificando quando os backups foram restaurados
DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)

SELECT
    TextData,
    Duration,
    StartTime,
    EndTime,
    SPID,
    ApplicationName,
    LoginName
FROM
    sys.fn_trace_gettable(@path, DEFAULT)
WHERE
    EventClass IN ( 115 ) 
    AND EventSubClass = 2
ORDER BY
    StartTime DESC

