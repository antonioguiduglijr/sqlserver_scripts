SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



/*** 
   Autor....: Antonio Guidugli Junior
   Data.....: 20/01/2008
   Descricao: Registrar informacoes sobre conexoes de usuarios
   Alteracao: 12/12/2018 - atualizacao
              11/10/2019 - atualizacao
              27/06/2020 - adicao da coluna ip_client
***/

CREATE   PROCEDURE [dbo].[sp_dba_log_conex]
AS
BEGIN

   -- cria tabela para registrar tamanho das bases de dados
   IF OBJECT_ID( 'dba_db.dbo.log_conex' ) IS NULL
   BEGIN
      ---drop table log_conex
      CREATE TABLE dbo.log_conex ( id			INT				NOT NULL IDENTITY(1,1),
								   dbid			SMALLINT		NOT NULL,
								   login_time	DATETIME		NOT NULL, 
								   hostname		VARCHAR(100)	NOT NULL, 
								   loginame		VARCHAR(100)	NOT NULL,
								   dbname		VARCHAR(100)	NOT NULL,
								   programname  VARCHAR(100)	NULL,
								   ip_client    VARCHAR(25)     NULL
								   )
      CREATE NONCLUSTERED INDEX [IX_log_conex_01] ON dbo.log_conex ( login_time, loginame, hostname, dbid )
   END

   -- registra conexoes do servidor
   INSERT INTO dbo.log_conex( dbid, login_time, hostname, loginame, dbname, programname, ip_client )
   SELECT DISTINCT 
          A.dbid, 
          A.login_time, 
          LEFT( A.hostname, 100 ) AS hostname, 
          LEFT( A.loginame, 100 ) AS loginame,
          LEFT( DB_NAME( A.dbid ), 100 ) AS dbname,
		  LEFT( program_name, 100 ) AS programname,
		  CONVERT(varchar(25), C.client_net_address ) AS ip_client
     FROM master.sys.sysprocesses A
     LEFT 
     JOIN dbo.log_conex           B ON B.dbid       = A.dbid       AND
                                       B.login_time = A.login_time AND
                                       B.hostname   = A.hostname   COLLATE Latin1_General_100_CI_AI AND
                                       B.loginame   = A.loginame   COLLATE Latin1_General_100_CI_AI 
     LEFT 
     JOIN master.sys.dm_exec_connections C ON C.session_id = A.spid                                       
    WHERE A.dbid > 5  -- bases de dados dos usuarios
      AND A.spid > 50 -- somente conexoes de usuarios
	  --AND A.LOGINAME NOT IN ( 'app.zabixx' ) -- desconsiderados
      AND B.dbid IS NULL

END	  

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


/*********


CREATE   PROCEDURE [dbo].[sp_dba_log_conex_clear] 
    @p_diasManter INT 
AS
BEGIN 

   DECLARE @Dt_Carencia DATETIME
   SET @Dt_Carencia = DATEADD( DD, (-1 * @p_diasManter), GETDATE())
   
   IF OBJECT_ID( 'dba_db.dbo.log_conex' ) IS NOT NULL
   BEGIN

      DELETE dbo.log_conex WHERE login_time <= @Dt_Carencia

   END	  

END

***********/



