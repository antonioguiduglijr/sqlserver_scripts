-- Verificar tabelas em ingles com dados armazenados

/**
--http://stackoverflow.com/questions/4130462/return-value-from-execsql
declare @var int
set @var = 1
exec sp_executesql N'select @var=count(*) FROM [WKPAuthorization].[IdlePolicy]', 
                    N'@var int output', @var output;
if @var = 0 PRINT 'zero'

**/


DECLARE @sch SYSNAME
DECLARE @tab SYSNAME
DECLARE @cnt INT
DECLARE @cmd NVARCHAR(500)

SET @cnt = 0

DECLARE MS_CRS_C1 CURSOR FOR
SELECT s.name as sch, t.name as tab--, 'SELECT COUNT(1) FROM [' + s.name + '].[' + t.name + ']'
  FROM sys.tables t
  JOIN sys.schemas  s ON s.schema_id = t.schema_id
 WHERE t.type = 'U'
   AND s.name IN ( 'WKPAuthorization', 'WKPGeneral', 'WKPLicense', 'WKPLicense', 'WKPCommon' ) -- schemas em ingles
 ORDER BY 1, 2

OPEN MS_CRS_C1
FETCH MS_CRS_C1 INTO @sch, @tab

WHILE @@FETCH_STATUS >= 0
BEGIN

   SET @cmd = 'SELECT @cnt = COUNT(1) FROM [' + @sch + '].[' + @tab + ']'
   --PRINT @cmd
   EXEC sp_executesql @cmd, N'@cnt INT OUTPUT', @cnt OUTPUT;
   IF @cnt > 0 
      PRINT @sch+'.'+@tab

   FETCH MS_CRS_C1 INTO @sch, @tab

END
DEALLOCATE MS_CRS_C1
