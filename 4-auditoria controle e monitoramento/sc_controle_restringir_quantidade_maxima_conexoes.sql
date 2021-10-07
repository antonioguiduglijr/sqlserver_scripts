--http://www.dirceuresende.com/blog/como-implementar-auditoria-e-controle-de-logins-no-sql-server/
--Limitando o numero de conexões máximas do usuário

USE [master]
GO

IF ((SELECT COUNT(*) FROM sys.server_triggers WHERE name = 'trgBloquear_Login_Sessoes') &gt; 0) DROP TRIGGER [trgBloquear_Login_Sessoes] ON ALL SERVER
GO

CREATE TRIGGER [trgBloquear_Login_Sessoes] ON ALL SERVER
WITH EXECUTE AS SELF
FOR LOGON
AS
BEGIN


    -- Não elimina conexões de usuários de sistema
    IF (ORIGINAL_LOGIN() IN ('sa', 'AUTORIDADE NT\SISTEMA', 'NT AUTHORITY\SYSTEM'))
        RETURN
        
        
    -- Verifica se o usuário é sysadmin
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
            PRINT 'Número máximo de conexões atingidas para este usuário neste servidor'
            ROLLBACK
            RETURN
        END
        
    END
       

END
GO

ENABLE TRIGGER [trgBloquear_Login_Sessoes] ON ALL SERVER  
GO