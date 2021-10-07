
SELECT *
FROM fn_trace_gettable
('C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\log.trc', default)
WHERE TextData LIKE '%wk_integracao%'
GO



--https://arstechnica.com/civis/viewtopic.php?f=17&t=1172332
SELECT databaseName, NTUserName, SessionLoginName, StartTime, * 
FROM fn_trace_gettable('C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\log.trc', default)
WHERE StartTime >= getdate() - 2 -- Last 2 day
AND EventClass = 47 -- Object:Deleted
AND ObjectType = 16964 -- Database



/***

SELECT cat.name AS Category
, b.name AS EventCaptured
, c.name AS ColumnCaptured
FROM fn_trace_geteventinfo(1) AS a
INNER JOIN sys.trace_events AS b
ON a.eventid = b.trace_event_id
INNER JOIN sys.trace_columns AS c
ON a.columnid = c.trace_column_id
INNER JOIN sys.trace_categories AS cat
ON b.category_id = cat.category_id
ORDER BY Category, EventCaptured, ColumnCaptured


***/

