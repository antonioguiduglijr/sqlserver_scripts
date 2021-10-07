USE MASTER
GO

-- 0 se for banco Secundario de LogShipping, colocar OFF-Line primeiro
--ALTER DATABASE [database_name_LS] SET OFFLINE WITH ROLLBACK IMMEDIATE

select * from sys.master_files where database_id = db_id('database_name')


-- 1 mover path do file do database
ALTER DATABASE [database_name] MODIFY FILE ( NAME = als_operacao_idx_dev, FILENAME = 'M:\DISCO2\index_desenv_ab\database_name.ndf' )
GO

sp_helpdb 'database_name'

-- 2 desabilitar job de backup Log Shipping
-->>> "[BKP900] LSBackup_xxxxxx_db"

-- 3 colocar banco off-line
ALTER DATABASE [database_name_LS] SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

-- 4 copiar file para novo path
--->> SO

-- 5 colocar banco on-line
ALTER DATABASE [database_name_LS] SET ONLINE 
GO

-- 6 habilitar job de backup Log Shipping
-->>> "[BKP900] LSBackup_crm_db"



/***
select * from sys.master_files where database_id = db_id( 'database_name_LS' )
select db_name(database_id), * from sys.master_files where physical_name like 'd:\index%'

--- restore de log
restore log [database_name_LS] from disk = 'D:\dumps\log\database_name_LS\database_name_LS_20140603210041.trn' 
with standby = 'D:\dumps\log\database_name_LS\database_name_LS_20140603210041.tuf' , stats = 1

sp_who2 active
dbcc inputbuffer (60) 


**/