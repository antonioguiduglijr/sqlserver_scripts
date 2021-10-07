-- Querys TOP 10
--https://pedrogalvaojunior.wordpress.com/2016/04/27/dica-do-mes-identificando-as-top-10-querys-mais-pesadas-e-seus-respectivos-planos-de-execucao/
SELECT TOP 10 
		--IDENTITY(INT, 1,1) AS ITEM,
		SUBSTRING(qt.TEXT,(qs.statement_start_offset / 2) + 1,((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(qt.TEXT) ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2) + 1) As 'Query',
		qs.execution_count As 'Execution Count',

		qs.total_logical_reads As 'Total Logical Reads',
		( qs.total_logical_reads / qs.execution_count ) AS 'Media Total Logical Reads',
		--qs.last_logical_reads As 'Last Logical Reads',
		--qs.min_logical_reads As 'Min Logical Reads',
		--qs.min_logical_reads As 'Max Logical Reads',

		qs.total_logical_writes As 'Total Logical Writes',
		( qs.total_logical_writes / qs.execution_count ) AS 'Media Total Logical Writes',
		--qs.last_logical_writes As 'Last Logical Writes',
		--qs.min_logical_writes As 'Min Logical Writes',
		--qs.max_logical_writes As 'Max Logical Writes',

		qs.total_worker_time As 'Total Worker Time',
		( qs.total_worker_time / qs.execution_count ) AS 'Media Total Worker Time',
		--qs.last_worker_time As 'Last Worker Time',
		--qs.min_worker_time As 'Min Worker Time',
		--qs.max_worker_time As 'Max Worker Time',

		qs.total_elapsed_time / 1000000 As 'Total Elapsed Time in seconds',
		( ( qs.total_elapsed_time / 1000000 ) / qs.execution_count ) AS 'Media Elapsed Time in seconds',
		--qs.last_elapsed_time / 1000000 As 'Last Elapsed Time in seconds',
		--qs.min_elapsed_time / 1000000 AS 'Min Elapsed Time in seconds',
		--qs.max_elapsed_time / 1000000 AS 'Max Elapsed Time in seconds',

		qs.last_execution_time As 'Last Execution Time',
		qp.query_plan As 'Query Execution Plan'
	--INTO #t
FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.execution_count DESC
--ORDER BY ( qs.total_logical_reads / qs.execution_count ) DESC

--SELECT * FROM #T
--drop table #t


---------------------------------- OR

--https://pt.stackoverflow.com/questions/227/como-posso-consultar-quais-s%C3%A3o-as-queries-mais-pesadas-no-sql-server
SELECT TOP 10
total_worker_time/execution_count AS Avg_CPU_Time
    ,execution_count
    ,total_elapsed_time/execution_count as AVG_Run_Time
    ,(SELECT
          SUBSTRING(text,statement_start_offset/2,(CASE
                                                       WHEN statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), text)) * 2 
                                                       ELSE statement_end_offset 
                                                   END -statement_start_offset)/2
                   ) FROM sys.dm_exec_sql_text(sql_handle)
     ) AS query_text 
FROM sys.dm_exec_query_stats 
--ORDER BY Avg_CPU_Time DESC
--ORDER BY AVG_Run_Time DESC
ORDER BY execution_count DESC
