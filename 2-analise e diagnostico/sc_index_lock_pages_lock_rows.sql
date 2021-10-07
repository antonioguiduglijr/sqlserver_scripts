--- https://www.mssqltips.com/sqlservertip/4247/resolve-sql-server-database-index-reorganization-page-level-locking-problem/
--- Checar/habilitar index com allow_page_locks ou allow_row_locks desabilitados
--- Boa pratica: Deixar a configuracao de ambos ON permite ao SQL Server decidir qual tipo de lock usar.
--- Exmeplo: 
--- ALTER INDEX [IX_nome_01] ON [dbo].[Table01] SET ( ALLOW_PAGE_LOCKS = ON )
--- ALTER INDEX [IX_nome_01] ON [dbo].[Table01] SET ( ALLOW_ROW_LOCKS = ON )

DECLARE @DBName NVARCHAR(150)
DECLARE @DynamicSQL NVARCHAR(300)

DECLARE @DBCursor CURSOR
SET @DBCursor = CURSOR FOR
 SELECT NAME FROM SYS.DATABASES
 WHERE NAME NOT IN ('master','tempdb','model','msdb')
   AND STATE = 0 -- online

OPEN @DBCursor
FETCH NEXT FROM @DBCursor INTO @DBName

WHILE @@FETCH_STATUS = 0
 BEGIN
  SET @DynamicSQL = 'SELECT * FROM [' + @DBName + ']' + '.sys.indexes WHERE allow_page_locks = 0 AND name <> ''queue_clustered_index'' AND name <> ''queue_secondary_index'''
  PRINT @DynamicSQL

  EXEC SP_EXECUTESQL @DynamicSQL

  FETCH NEXT FROM @DBCursor INTO @DBName
 END

CLOSE @DBCursor
DEALLOCATE @DBCursor

--SELECT *,'ALTER INDEX ['+name+'] ON ['+DB_NAME()+'].['+object_schema_name(object_id)+'].['+object_name(object_id)+'] SET ( ALLOW_PAGE_LOCKS = ON )' FROM [tfs_wolters_kluwer_prosoft].sys.indexes WHERE allow_page_locks = 0 AND name <> 'queue_clustered_index' AND name <> 'queue_secondary_index'
--SELECT *,'ALTER INDEX ['+name+'] ON ['+DB_NAME()+'].['+object_schema_name(object_id)+'].['+object_name(object_id)+'] SET ( ALLOW_ROW_LOCKS = ON )' FROM [tfs_wolters_kluwer_prosoft].sys.indexes WHERE allow_page_locks = 0 AND name <> 'queue_clustered_index' AND name <> 'queue_secondary_index'

