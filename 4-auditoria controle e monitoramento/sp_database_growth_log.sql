SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

USE dba_db
GO

/***
   Autor.....: Antonio Guidugli Junior
   Data......: 10/08/2007
   Descricao.: Lista bancos de dados por ordem descrescente de tamanho
   Manutencao: 31/01/2008 - Registra tamanhos dos bancos de dados
   Manutencao: 17/07/2018 - Adaptado para SQL 2016 na WK
***/
DROP PROCEDURE [dbo].[sp_DBA_DB_Growth_Log]
GO 
CREATE PROCEDURE [dbo].[sp_DBA_DB_Growth_Log]
AS

   -- cria tabela para registrar tamanho das bases de dados
   IF NOT EXISTS ( SELECT 1 FROM master.dbo.sysobjects WHERE name = 'Historico_DB_Growth' )
   BEGIN
      --DROP TABLE dba_db.dbo.Historico_DB_Growth
      CREATE TABLE dbo.Historico_DB_Growth ( Id          INT           NOT NULL IDENTITY(1,1),
	                                         DataHora    DATETIME      NULL,
                                             ServerName  VARCHAR(50)   NULL,
                                             DBId        SMALLINT      NULL,
                                             DBName      SYSNAME       NULL,
                                             DataMB      INT           NULL,
											 LogMB       INT           NULL )
   END

   -- registra tamanho atual dos bancos de dados
   INSERT INTO dbo.Historico_db_growth ( DataHora, ServerName, DBId, DBName, DataMB, LogMB )
   SELECT GETDATE() ASDataHora,
          @@SERVERNAME AS ServerName,
		  database_id AS DBId,
          DB_NAME(database_id) AS DBName, 
          SUM( CASE WHEN TYPE = 0 THEN (size*8/1024) ELSE 0 END ) AS DataMB,
          SUM( CASE WHEN TYPE = 1 THEN (size*8/1024) ELSE 0 END ) AS LogMB 
          FROM sys.master_files 
		  WHERE database_id <> 3
          GROUP BY database_id
          ORDER BY 1

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

