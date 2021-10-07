------ FileGroup dos objetos
--http://www.sqlservercentral.com/blogs/jeffrey_yao/2009/01/16/list-objects-in-a-filegroup-in-sql-server-2005/
--sp_ObjectFileGroup @objid = 1553596773

SELECT FileGroup = FILEGROUP_NAME(a.data_space_id),
       TableName = OBJECT_NAME(p.object_id),
       IndexName = i.name
  FROM sys.allocation_units a
 INNER 
  JOIN sys.partitions p ON a.container_id = CASE WHEN a.type in(1,3) THEN p.hobt_id ELSE p.partition_id END AND p.object_id > 1024
  LEFT 
  JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id
  --WHERE FILEGROUP_NAME(a.data_space_id) NOT IN ( 'PRIMARY', 'INDEX' )
 ORDER BY FileGroup



SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name]
  FROM sys.indexes i
 INNER 
  JOIN sys.filegroups  f ON i.data_space_id = f.data_space_id
 INNER 
  JOIN sys.all_objects o ON i.[object_id] = o.[object_id]
 WHERE i.data_space_id = f.data_space_id AND 
       o.type = 'U' -- User Created Tables
GO