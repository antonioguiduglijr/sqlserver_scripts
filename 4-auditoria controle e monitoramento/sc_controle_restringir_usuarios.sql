--https://www.dirceuresende.com/blog/como-implementar-auditoria-e-controle-de-logins-no-sql-server-trigger-logon/
USE [master]
GO

IF ((SELECT COUNT(*) FROM sys.server_triggers WHERE name = 'trgBloquear_Login') > 0) DROP TRIGGER [trgBloquear_Login] ON ALL SERVER
GO

CREATE TRIGGER [trgBloquear_Login] ON ALL SERVER
FOR LOGON 
AS
BEGIN


    -- Não elimina conexões de usuários de sistema
    IF (ORIGINAL_LOGIN() IN ('sa', 'AUTORIDADE NT\SISTEMA', 'NT AUTHORITY\SYSTEM', 'WK-V7-BD\svc.sqlserver'))
        RETURN
    
    -- Não elimina conexões de usuários administradores
    IF (ORIGINAL_LOGIN() IN ('antonio.guidugli', 'WK-V7-BD\antonio.guidugli', 'WK-V7-BD\carla.vicente' ))
        RETURN
    
    
    DECLARE 
        @Evento XML, 
        @Dt_Evento DATETIME,
        @Ds_Usuario VARCHAR(100),
        @Ds_Usuario_Original VARCHAR(100),
        @Ds_Tipo_Usuario VARCHAR(30),
        @Ds_Ip VARCHAR(30),
        @SPID SMALLINT,
        @Ds_Hostname VARCHAR(100),
        @Ds_Software VARCHAR(100)
        


    SET @Evento = EVENTDATA()

    
    SELECT 
        @Dt_Evento = @Evento.value('(/EVENT_INSTANCE/PostTime/text())[1]','datetime'),
        @Ds_Usuario = @Evento.value('(/EVENT_INSTANCE/LoginName/text())[1]','varchar(100)'),
        @Ds_Tipo_Usuario = @Evento.value('(/EVENT_INSTANCE/LoginType/text())[1]','varchar(30)'),
        @Ds_Hostname = HOST_NAME(),
        @Ds_Ip = @Evento.value('(/EVENT_INSTANCE/ClientHost/text())[1]','varchar(100)'),
        @SPID = @Evento.value('(/EVENT_INSTANCE/SPID/text())[1]','smallint'),
        @Ds_Software = PROGRAM_NAME()
         
         

    IF (@Ds_Usuario IN ('Usuario_Teste'))
    BEGIN
        PRINT 'Usuário não permitido para logar neste servidor. Favor entrar em contato com a equipe de Banco de Dados'
        ROLLBACK
    END
    
    
    IF (@Ds_Tipo_Usuario = 'SQL Login')
    BEGIN
        PRINT 'Usuários SQL não são permitidos nesse servidor. Favor entrar em contato com a equipe de Banco de Dados'
        ROLLBACK
    END
    
            

END
GO

ENABLE TRIGGER [trgBloquear_Login] ON ALL SERVER  
GO
