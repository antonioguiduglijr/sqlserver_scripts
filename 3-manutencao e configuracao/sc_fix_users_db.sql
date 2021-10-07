/************************************************************************
* Objetivo: Associa os usuarios de um database a seu respectivo	login.  *
* ATENÇÃO: O LOGIN E O USUÁIO DENTRO DA BASE DEVEM TER O MESMO NOME     *
************************************************************************/
--https://www.sqlshack.com/creating-a-stored-procedure-to-fix-orphaned-database-users/

--- fix users 2017

--CREATE PROCEDURE [dbo].[OrphanDBUsersAutoFix] (@mode VARCHAR(10))
--AS
--BEGIN
	SET NOCOUNT ON
	DECLARE @tsql VARCHAR(400)
	DECLARE @username SYSNAME

	DECLARE c_orphanedusers CURSOR
	FOR  SELECT a.NAME AS OrphUsr
	FROM sys.database_principals a
	LEFT OUTER JOIN sys.server_principals b
		ON a.sid = b.sid
	WHERE (b.sid IS NULL)  	AND (a.principal_id > 4) 	AND (a.type_desc = 'SQL_USER')

	OPEN c_orphanedusers
	FETCH c_orphanedusers
	INTO @username
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @tsql = 'ALTER USER [' + @username + '] WITH LOGIN = [' + @username + ']';
		--IF UPPER(@mode) = 'EXECUTE'
			EXEC (@tsql)
		--ELSE
		--	IF UPPER(@mode) = 'REPORT'
		--		PRINT (@tsql)

		FETCH c_orphanedusers  	INTO @username
	END
	CLOSE c_orphanedusers
	DEALLOCATE c_orphanedusers
	IF (
			SELECT count(a.NAME) AS OrphUsr
			FROM sys.database_principals a
			LEFT OUTER JOIN sys.server_principals b
				ON a.sid = b.sid
			WHERE (b.sid IS NULL)
				AND (a.principal_id > 4)
				AND (a.type_desc = 'SQL_USER')
			) = 0
		PRINT 'No Orphaned SQL Users.'
	SET NOCOUNT OFF
--END
--GO


/******** OLD VERSION

-- ATENçÂO: Pode default varre todos os dbs. 
-- Para verificar um banco específico troque SET @db = NULL por pelo nome do db desejado
-- Exemplo: SET @db = 'Pubs'

USE MASTER
GO
SET NOCOUNT ON
--> Declaracao de Variaveis
DECLARE @sql 	nvarchar(1000)
DECLARE @User	sysname
DECLARE @db	varchar(30)

SET @db = 'ofc2cnd' --- nome do banco de dados

CREATE TABLE #tbUsuarios (usuarios sysname)
IF @db is not null -- Para um db específico
BEGIN
	SET @sql = 'SELECT usu.name FROM '+@db+'.dbo.sysusers usu  
				LEFT OUTER JOIN master.dbo.syslogins lo 
				ON usu.sid = lo.sid
	  			WHERE (usu.islogin = 1 AND usu.isaliased = 0 AND usu.hasdbaccess = 1)
				AND lo.loginname is null'
	INSERT INTO #tbUsuarios exec sp_executesql @sql	
	IF exists(SELECT usuarios FROM #tbUsuarios)
	BEGIN
		SELECT @User = min(usuarios) from #tbUsuarios
		WHILE @User is not null
		BEGIN
			SELECT @sql = @db+'.dbo.sp_change_users_login ''Update_One'','''+ @User + ''','''+ @User +''''
			EXEC sp_executesql @sql
			SET @sql = 'O usuário '''+ @User +''' do database '''+@db +''' foi associado ao seu login '''+@User+''''
			Print @sql
			SELECT @User = min(usuarios) from #tbUsuarios where usuarios > @User			
		END
	END
END
ELSE
BEGIN
	-- Pesquisa em todos os dbs
	SELECT @db = min(name) from master.dbo.sysdatabases where name not in ('tempdb', 'pubs', 'msdb', 'NorthWind', 'master','model')
	WHILE @db is not null
	BEGIN
		SET @sql = 'SELECT usu.name FROM '+@db+'.dbo.sysusers usu  
				LEFT OUTER JOIN master.dbo.syslogins lo 
				ON usu.sid = lo.sid
	  			WHERE (usu.islogin = 1 AND usu.isaliased = 0 AND usu.hasdbaccess = 1)
				AND lo.loginname is null'	
		INSERT INTO	#tbUsuarios exec sp_executesql @sql
		IF exists(SELECT usuarios FROM #tbUsuarios)
		BEGIN
			SELECT @User = min(usuarios) from #tbUsuarios
			WHILE @User is not null
			BEGIN
				SET @sql = @db+'..sp_change_users_login ''Update_One'','''+ @User + ''','''+ @User +''''
				EXEC sp_executesql @sql
				SET @sql = 'O usuário '''+ @User +''' do database '''+@db +''' foi associado ao seu login '''+@User+''''
				Print @sql
				SELECT @User = min(usuarios) from #tbUsuarios where usuarios > @User				
			END
		END
		DELETE #tbUsuarios
		SELECT @db = min(name) FROM master.dbo.sysdatabases WHERE name not in ('tempdb', 'pubs', 'msdb', 'NorthWind', 'master','model')
		AND Name > @db
	END
END
GO
DROP TABLE #tbUsuarios

***********/

