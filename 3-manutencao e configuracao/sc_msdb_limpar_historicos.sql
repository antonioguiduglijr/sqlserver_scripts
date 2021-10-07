--- Limpar MSDB
-- Antonio Guidugli Junior - 16/08/2018


USE msdb
GO 

EXEC sp_delete_backuphistory @oldest_date = '08/10/2018';  
GO
EXEC sysmail_delete_mailitems_sp @sent_before = '07/01/2018';
GO


--Limpando as tabelas email
TRUNCATE TABLE sysmail_attachments;
--TRUNCATE TABLE sysmail_mailitems;
DELETE sysmail_mailitems;
DELETE sysmail_log
GO


--Criando uma transação para executar esta tarefa -- https://social.technet.microsoft.com/wiki/pt-br/contents/articles/32505.sql-server-reduzindo-o-tamanho-do-banco-de-dados-msdb.aspx
BEGIN TRAN

--Remove temporariamente a "constraint" para limpeza das tabelas
ALTER TABLE sysmaintplan_log            DROP CONSTRAINT FK_sysmaintplan_log_subplan_id;
ALTER TABLE sysmaintplan_logdetail      DROP CONSTRAINT FK_sysmaintplan_log_detail_task_id;
GO

--Limpando as tabelas
TRUNCATE TABLE sysmaintplan_logdetail;
TRUNCATE TABLE sysmaintplan_log;
GO

--Recriando as "constraint's" para preservar a integridade dos dados
ALTER TABLE sysmaintplan_log WITH CHECK ADD CONSTRAINT FK_sysmaintplan_log_subplan_id FOREIGN KEY(subplan_id) REFERENCES sysmaintplan_subplans (subplan_id);
ALTER TABLE sysmaintplan_logdetail WITH CHECK ADD CONSTRAINT FK_sysmaintplan_log_detail_task_id FOREIGN KEY(task_detail_id) REFERENCES sysmaintplan_log (task_detail_id) ON DELETE CASCADE;
GO

IF @@ERROR = 0
	COMMIT TRAN
ELSE
	ROLLBACK TRAN
GO

---- recicla o errorlog
sp_cycle_errorlog



---- shrink
USE msdb
GO
 
DBCC SHRINKFILE(MSDBLog, 512)
GO 
DBCC SHRINKFILE(MSDBData, 1024)
GO
