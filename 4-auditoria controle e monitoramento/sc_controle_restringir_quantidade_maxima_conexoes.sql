--http://www.dirceuresende.com/blog/como-implementar-auditoria-e-controle-de-logins-no-sql-server/
--Limitando o numero de conex�es m�ximas do usu�rio

USE [master]
GO

IF ((SELECT COUNT(*) FROM sys.server_triggers WHERE name = 'trgBloquear_Login_Sessoes') &gt; 0) DROP TRIGGER [trgBloquear_Login_Sessoes] ON ALL SERVER
GO

CREATE TRIGGER [trgBloquear_Login_Sessoes] ON ALL SERVER
WITH EXECUTE AS SELF
FOR LOGON
AS
BEGIN


    -- N�o elimina conex�es de usu�rios de sistema
    IF (ORIGINAL_LOGIN() IN ('sa', 'AUTORIDADE NT\SISTEMA', 'NT AUTHORITY\SYSTEM'))
        RETURN
        
        
    -- Verifica se o usu�rio � sysadmin
    DECLARE @IsSysAdmin int
    EXECUTE AS CALLER
    SET @IsSysAdmin = ISNULL(IS_SRVROLEMEMBER('sysadmin'), 0)
    REVERT
        
        
    IF (@IsSysAdmin = 0)
    BEGIN
        
        IF ((
            SELECT COUNT(*) 
            FROM sys.dm_exec_sessions 
            WHERE is_user_process = 1 
            AND login_name = ORIGINAL_LOGIN()
            AND [program_name] NOT LIKE 'Red Gate%'
            AND [program_name] NOT LIKE '%IntelliSense%'
        ) &gt; 2)
        BEGIN
            PRINT 'N�mero m�ximo de conex�es atingidas para este usu�rio neste servidor'
            ROLLBACK
            RETURN
        END
        
    END
       

END
GO

ENABLE TRIGGER [trgBloquear_Login_Sessoes] ON ALL SERVER  
GO