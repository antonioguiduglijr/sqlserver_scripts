--- Antonio Guidugli Junior
--- Checar indexes com zero leituras desde a ultima inicialização do SQL Server

-- SELECT sqlserver_start_time FROM sys.dm_os_sys_info


EXEC sp_MSforeachdb 'use [?];
SELECT @@servername as server_name,
       db_name() as db,
       o.name,
       i.name as indexname,
       i.index_id,
       user_seeks + user_scans + user_lookups as reads,
       user_updates as writes,
       (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id) as rows
  FROM sys.dm_db_index_usage_stats s  
 INNER 
  JOIN sys.indexes                 i ON i.index_id = s.index_id AND s.object_id = i.object_id   
 INNER
  JOIN sys.objects                 o on s.object_id = o.object_id
 INNER
  JOIN sys.schemas                 c on o.schema_id = c.schema_id
 WHERE OBJECTPROPERTY(s.object_id,''IsUserTable'') = 1
   AND s.database_id = DB_ID()   
   AND s.database_id > 4
   AND i.type_desc = ''nonclustered''
   AND i.is_primary_key = 0
   AND i.is_unique_constraint = 0
   AND (user_seeks + user_scans + user_lookups) = 0
 ORDER BY reads ASC, writes DESC
' 

-----

/**
SELECT @@servername as server_name,
       db_name() as db,
       o.name,
       i.name as indexname,
       i.index_id,
       user_seeks + user_scans + user_lookups as reads,
       user_updates as writes,
       (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id) as rows,
	   'drop index ['+i.name+'] on ['+o.name+']' as command
  FROM sys.dm_db_index_usage_stats s  
 INNER 
  JOIN sys.indexes                 i ON i.index_id = s.index_id AND s.object_id = i.object_id   
 INNER
  JOIN sys.objects                 o on s.object_id = o.object_id
 INNER
  JOIN sys.schemas                 c on o.schema_id = c.schema_id
 WHERE OBJECTPROPERTY(s.object_id,'IsUserTable') = 1
   AND s.database_id = DB_ID()   
   AND s.database_id > 4
   AND i.type_desc = 'nonclustered'
   AND i.is_primary_key = 0
   AND i.is_unique_constraint = 0
   AND (user_seeks + user_scans + user_lookups) = 0
 ORDER BY reads ASC, writes DESC
 **/
 
 
