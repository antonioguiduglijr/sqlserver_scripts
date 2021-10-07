--https://desktop.arcgis.com/en/arcmap/latest/extensions/data-reviewer-guide/admin-dr-sql-server/using-data-compression-for-the-reviewer-workspace-in-sql-server.htm#ESRI_SECTION1_08D273ED486C47838748506E31A9D2E9

-- examples
USE REVDB;
GO
EXEC sp_estimate_data_compression_savings 'rev', 'TableA', NULL, NULL,
'ROW';
GO

USE REVDB;
GO
EXEC sp_estimate_data_compression_savings 'rev', 'TableA', NULL, NULL,
'PAGE';
GO

--- estimate in all objects
--https://www.sqlservercentral.com/scripts/estimate-compression-for-all-tables-and-indexes-with-both-row-and-page

--------------------------------------------
--use P12_00
--GO
create table #CompressionEstimateResultSet (object_name sysname,schema_name sysname,index_id int,partition_number int null,
[size_with_current_compression_setting (KB)] bigint,[size_with_requested_compression_setting (KB)] Bigint,
[sample_size_with_current_compression_setting (KB)] bigint,[sample_size_with_requested_compression_setting (KB)] bigint,[data_Compression] varchar(4))
declare @CompressionEstimate table (object_name sysname,schema_name sysname,index_id int,partition_number int null,
[size_with_current_compression_setting (KB)] bigint,[size_with_requested_compression_setting (KB)] Bigint,
[sample_size_with_current_compression_setting (KB)] bigint,[sample_size_with_requested_compression_setting (KB)] bigint)

declare @schema_nameX sysname,@object_nameX sysname,@index_idX int
declare CompressionEstimateCursor cursor FOR 
 SELECT distinct
     s.name as schemaname, o.Name as tablename, i.Index_ID
  FROM sys.indexes AS i
       INNER JOIN sys.partitions AS p ON p.object_id = i.object_id
                                     AND p.index_id = i.index_id     
	  INNER JOIN sys.objects o on o.object_id = i.object_id
	  INNER JOIN sys.schemas s on s.schema_id = o.schema_id	
	  where i.object_id > 100 and s.name not in ('sys','CDC')  and rows > 500
open CompressionEstimateCursor
Fetch Next FROM CompressionEstimateCursor  into @schema_nameX ,@object_nameX ,@index_idX
   
While(@@FETCH_STATUS =0)   
BEGIN

    insert into @CompressionEstimate
    exec sp_estimate_data_compression_savings @schema_name = @schema_nameX,  @object_name =  @object_nameX 
   , @index_id =  @index_idX, @partition_number = null, @data_compression =  'Page' 

    insert into #CompressionEstimateResultSet(object_name ,schema_name ,index_id ,partition_number ,
    [size_with_current_compression_setting (KB)] ,[size_with_requested_compression_setting (KB)] ,
    [sample_size_with_current_compression_setting (KB)] ,[sample_size_with_requested_compression_setting (KB)] ,[data_Compression])
    Select object_name ,schema_name ,index_id ,partition_number ,
    [size_with_current_compression_setting (KB)] ,[size_with_requested_compression_setting (KB)] ,
    [sample_size_with_current_compression_setting (KB)] ,[sample_size_with_requested_compression_setting (KB)] ,'Page' as [data_Compression] 
    from @CompressionEstimate

    delete from  @CompressionEstimate

    insert into @CompressionEstimate
    exec sp_estimate_data_compression_savings @schema_name = @schema_nameX,  @object_name =  @object_nameX 
   , @index_id =  @index_idX, @partition_number = null, @data_compression =  'Row' 
    insert into #CompressionEstimateResultSet(object_name ,schema_name ,index_id ,partition_number ,
    [size_with_current_compression_setting (KB)] ,[size_with_requested_compression_setting (KB)] ,
    [sample_size_with_current_compression_setting (KB)] ,[sample_size_with_requested_compression_setting (KB)] ,[data_Compression])
    Select object_name ,schema_name ,index_id ,partition_number ,
    [size_with_current_compression_setting (KB)] ,[size_with_requested_compression_setting (KB)] ,
    [sample_size_with_current_compression_setting (KB)] ,[sample_size_with_requested_compression_setting (KB)] ,'Row' as [data_Compression] 
    from @CompressionEstimate

    delete from  @CompressionEstimate
    Fetch Next FROM CompressionEstimateCursor  into @schema_nameX ,@object_nameX ,@index_idX
END
Close CompressionEstimateCursor
deallocate CompressionEstimateCursor

select *,cast(100.0 *[sample_size_with_requested_compression_setting (KB)]/[sample_size_with_current_compression_setting (KB)] as int) AS 'CompressionRatio(%)' ,
[size_with_current_compression_setting (KB)] - [size_with_requested_compression_setting (KB)] 'EstimatedSpaceSaving'
from #CompressionEstimateResultSet where [sample_size_with_current_compression_setting (KB)] > 0 
and 100.0 *[sample_size_with_requested_compression_setting (KB)]/[sample_size_with_current_compression_setting (KB)] < 80 order by 
[size_with_current_compression_setting (KB)] - [size_with_requested_compression_setting (KB)] desc

--drop table #CompressionEstimateResultSet
