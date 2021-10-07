/***
* Origem...: sp_spaceused (SQL 2005)
* Autor....: Antonio Guidugli Junior
* Descricao: Listar tabelas por espaco ocupado em KB no banco selecionado 
* Obs......: Pode-se usar: EXEC sp_MSforeachTable @command1="print '>>>Tabela: ?' ", @command2="sp_spaceused '?' "

--- opcao: select 'Exec SP_SpaceUsed  '+Name from sysobjects where xtype='u'
***/


-- Get Table names, row counts, and compression status for clustered index or heap  (Query 56) (Table Sizes)
SELECT OBJECT_NAME(object_id) AS [ObjectName], 
SUM(Rows) AS [RowCount], data_compression_desc AS [CompressionType]
FROM sys.partitions WITH (NOLOCK)
WHERE index_id < 2 --ignore the partitions from the non-clustered index if any
AND OBJECT_NAME(object_id) NOT LIKE N'sys%'
AND OBJECT_NAME(object_id) NOT LIKE N'queue_%' 
AND OBJECT_NAME(object_id) NOT LIKE N'filestream_tombstone%' 
AND OBJECT_NAME(object_id) NOT LIKE N'fulltext%'
AND OBJECT_NAME(object_id) NOT LIKE N'ifts_comp_fragment%'
AND OBJECT_NAME(object_id) NOT LIKE N'xml_index_nodes%'
GROUP BY object_id, data_compression_desc
ORDER BY SUM(Rows) DESC OPTION (RECOMPILE);


--select * from sys.indexes
--select * from sys.objects

SELECT schema_name(o.schema_id) as schemaName,
       object_name(i.object_id) as objectName,
       i.[name] as indexName,
       sum(a.total_pages) as totalPages,
       sum(a.used_pages) as usedPages,
       sum(a.data_pages) as dataPages,
       (sum(a.total_pages) * 8) / 1024 as totalSpaceMB,
       (sum(a.used_pages) * 8) / 1024 as usedSpaceMB, 
       (sum(a.data_pages) * 8) / 1024 as dataSpaceMB
  FROM sys.indexes          i
  JOIN sys.objects          o ON o.object_id = i.object_id
  JOIN sys.partitions       p ON i.object_id = p.object_id
                             AND i.index_id  = p.index_id
  JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE o.type <> 'S'
 GROUP BY o.schema_id, i.object_id, i.index_id, i.[name]
 ORDER BY sum(a.total_pages) DESC, object_name(i.object_id)
GO


/*** VERSAO ANTIGA

DECLARE @id	             INT		
        --,@type	          CHARACTER(2) 
        ,@pages	         BIGINT			
        --,@dbname         SYSNAME
        --,@dbsize         BIGINT
        --,@logsize        BIGINT
        ,@reservedpages  BIGINT
        ,@usedpages      BIGINT
        ,@rowCount       BIGINT


/* cria tabela de resultados */
CREATE TABLE #resultado
(
        id          int null,
        nome        varchar(200) null,
        rows        numeric(20) null,
        reserved_kb dec(20) null,
        data_kb     dec(20) null,
        indexp_kb   dec(20) null,
        unused_kb   dec(20) null 
)


DECLARE ms_crs_c1 CURSOR FOR
 SELECT object_id FROM sys.objects WHERE type = 'U'

OPEN ms_crs_c1
FETCH ms_crs_c1 INTO @id

WHILE @@fetch_status >= 0
BEGIN

	  /*
	  ** Now calculate the summary data. 
	  *  Note that LOB Data and Row-overflow Data are counted as Data Pages.
	  */
	  SELECT @reservedpages = SUM ( reserved_page_count ),
		        @usedpages     = SUM ( used_page_count ),
		        @pages         = SUM ( CASE
				                              WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
				                              ELSE lob_used_page_count + row_overflow_used_page_count
			                              END ),
		        @rowCount      = SUM ( CASE
				                              WHEN (index_id < 2) THEN row_count
				                              ELSE 0
			                              END )
	    FROM sys.dm_db_partition_stats
    WHERE object_id = @id;

	  /*
	  ** Check if table has XML Indexes or Fulltext Indexes which use internal tables tied to this table
	  */
	  IF (SELECT count(*) FROM sys.internal_tables WHERE parent_id = @id AND internal_type IN (202,204)) > 0 
	  BEGIN
		    /*
		    **  Now calculate the summary data. Row counts in these internal tables don't 
		    **  contribute towards row count of original table.  
		    */
		    SELECT @reservedpages = @reservedpages + sum(reserved_page_count),
			          @usedpages     = @usedpages     + sum(used_page_count)
  		    FROM sys.dm_db_partition_stats p, 
		           sys.internal_tables it
		     WHERE it.parent_id = @id AND it.internal_type IN (202,204) AND p.object_id = it.object_id;
	  END

   INSERT INTO #resultado ( id, nome, rows, reserved_kb, data_kb, indexp_kb, unused_kb )
	  SELECT id          = @id ,
		        nome        = OBJECT_NAME (@id),
		        rows        = @rowCount, --convert (char(11), @rowCount),
		        reserved_kb = ( @reservedpages * 8 ), --LTRIM (STR (@reservedpages * 8, 15, 0) + ' KB'),
		        data_kb     = (@pages * 8), --LTRIM (STR (@pages * 8, 15, 0) + ' KB'),
		        indexp_kb   = ((CASE WHEN @usedpages > @pages THEN (@usedpages - @pages) ELSE 0 END) * 8 ), --LTRIM (STR ((CASE WHEN @usedpages > @pages THEN (@usedpages - @pages) ELSE 0 END) * 8, 15, 0) + ' KB'),
		        unused_kb   = ((CASE WHEN @reservedpages > @usedpages THEN (@reservedpages - @usedpages) ELSE 0 END) * 8 ) --LTRIM (STR ((CASE WHEN @reservedpages > @usedpages THEN (@reservedpages - @usedpages) ELSE 0 END) * 8, 15, 0) + ' KB')

	  FETCH ms_crs_c1 INTO @id

END

DEALLOCATE ms_crs_c1

SELECT *--, CONVERT( DECIMAL(10,2), ( reserved_kb / rows ) ) AS media_registro
  FROM #resultado 
 --WHERE nome = 'B06'
 ORDER BY reserved_kb DESC --data_kb desc


DROP TABLE #resultado

****/
