--https://www.red-gate.com/simple-talk/sql/performance/which-of-your-stored-procedures-are-using-the-most-resources/
SELECT CASE WHEN database_id = 32767 then 'Resource' ELSE DB_NAME(database_id)END AS DBName
      ,OBJECT_SCHEMA_NAME(object_id,database_id) AS [SCHEMA_NAME]  
      ,OBJECT_NAME(object_id,database_id)AS [OBJECT_NAME]
      ,cached_time
      ,last_execution_time
      ,execution_count
      ,total_worker_time / execution_count AS AVG_CPU
      ,total_elapsed_time / execution_count AS AVG_ELAPSED
      ,total_logical_reads / execution_count AS AVG_LOGICAL_READS
      ,total_logical_writes / execution_count AS AVG_LOGICAL_WRITES
      ,total_physical_reads  / execution_count AS AVG_PHYSICAL_READS
FROM sys.dm_exec_procedure_stats  
ORDER BY AVG_LOGICAL_READS DESC


---------------------------- OR

--https://www.mssqltips.com/sqlservertip/5377/function-to-quickly-find-the-worst-performing-sql-server-stored-procedures/
   SELECT TOP 10
      DB_NAME (database_id) AS DBName,
      OBJECT_SCHEMA_NAME (object_id, database_id) AS [Schema_Name],
      OBJECT_NAME (object_id, database_id) AS [Object_Name],
      total_elapsed_time / execution_count AS Avg_Elapsed_Time,
      (total_physical_reads + total_logical_reads) / execution_count AS Avg_Reads,
      execution_count AS Execution_Count,
      t.text AS Query_Text,
      H.query_plan AS Query_Plan
   FROM 
      sys.dm_exec_procedure_stats
      CROSS APPLY sys.dm_exec_sql_text(sql_handle) T
      CROSS APPLY sys.dm_exec_query_plan(plan_handle) H
  -- WHERE 
      --LOWER(DB_NAME(database_id)) LIKE LOWER(@dbname) 
      --AND total_elapsed_time / execution_count > @avg_time_threshhold 
      --AND 
	  --LOWER(DB_NAME (database_id)) NOT IN ('master','tempdb','model','msdb','resource')
   ORDER BY 
       avg_elapsed_time DESC

