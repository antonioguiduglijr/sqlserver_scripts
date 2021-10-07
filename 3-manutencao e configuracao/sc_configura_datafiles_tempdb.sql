/***
* Autor....: Antonio Guidugli Junior
* Descricao: Altera fisicamente os arquivos do banco de dados TempDB
--- pesquisar TraceFlag Tempdb 1117 ou 1118
***/

use tempdb
go
select * from sys.master_files
go

-- altera log para maximo 40GB
ALTER DATABASE tempdb MODIFY FILE (NAME = templog, FILENAME = 'D:\templog.ldf', SIZE = 1024 MB, FILEGROWTH = 1024 MB )

-- altera data primario para maximo de 8GB (total 64GB)
ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, FILENAME = 'D:\tempdb.mdf', SIZE = 1024 MB, FILEGROWTH = 1024 MB )

-- adiciona arquivos 7 arquivo de no maximo 8GB cada um
ALTER DATABASE tempdb ADD FILE (NAME = tempdev1, FILENAME = 'D:\tempdb1.ndf', SIZE = 1024 MB, FILEGROWTH = 1024 MB )
ALTER DATABASE tempdb ADD FILE (NAME = tempdev2, FILENAME = 'D:\tempdb2.ndf', SIZE = 1024 MB, FILEGROWTH = 1024 MB )
ALTER DATABASE tempdb ADD FILE (NAME = tempdev3, FILENAME = 'D:\tempdb3.ndf', SIZE = 1024 MB, FILEGROWTH = 1024 MB )
ALTER DATABASE tempdb ADD FILE (NAME = tempdev4, FILENAME = 'D:\tempdb4.ndf', SIZE = 1024 MB, MAXSIZE = 8192 MB, FILEGROWTH = 1024 MB )
ALTER DATABASE tempdb ADD FILE (NAME = tempdev5, FILENAME = 'D:\tempdb5.ndf', SIZE = 1024 MB, MAXSIZE = 8192 MB, FILEGROWTH = 1024 MB )
ALTER DATABASE tempdb ADD FILE (NAME = tempdev6, FILENAME = 'D:\tempdb6.ndf', SIZE = 1024 MB, MAXSIZE = 8192 MB, FILEGROWTH = 1024 MB )
ALTER DATABASE tempdb ADD FILE (NAME = tempdev7, FILENAME = 'D:\tempdb7.ndf', SIZE = 1024 MB, MAXSIZE = 8192 MB, FILEGROWTH = 1024 MB )



---- remover files extras
-- 1
USE tempdb
GO
DBCC SHRINKFILE (tempdev8, EMPTYFILE); 
GO
-- 2
ALTER DATABASE tempdb REMOVE FILE tempdev8;
GO



-- altera log para maximo 40GB
ALTER DATABASE tempdb MODIFY FILE (NAME = templog, FILENAME = 'D:\templog.ldf' )

-- altera data primario para maximo de 8GB (total 64GB)
ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, FILENAME = 'D:\tempdb.mdf' )

