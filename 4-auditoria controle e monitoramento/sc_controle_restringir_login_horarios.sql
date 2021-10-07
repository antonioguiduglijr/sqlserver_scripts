--http://www.dirceuresende.com/blog/como-implementar-auditoria-e-controle-de-logins-no-sql-server/
--Impedindo login em um determinado hor�rio

USE [master]
GO

IF ((SELECT COUNT(*) FROM sys.server_triggers WHERE name = 'trgBloquear_Login_Horario') &gt; 0) DROP TRIGGER [trgBloquear_Login_Horario] ON ALL SERVER
GO

CREATE TRIGGER [trgBloquear_Login_Horario] ON ALL SERVER
FOR LOGON 
AS
BEGIN


    -- N�o elimina conex�es de usu�rios de sistema
    IF (ORIGINAL_LOGIN() IN ('sa', 'AUTORIDADE NT\SISTEMA', 'NT AUTHORITY\SYSTEM'))
        RETURN
    
    
    IF (DATEPART(WEEKDAY, GETDATE()) IN (0, 7))
    BEGIN
        PRINT 'Conex�es aos fins de semana n�o s�o permitidas neste servidor'
        ROLLBACK
        RETURN
    END
    
    
    IF (DATEPART(HOUR, GETDATE()) &gt;= 18 OR DATEPART(HOUR, GETDATE()) &lt; 8)
    BEGIN
        PRINT 'Conex�es antes das 8h e depois das 18h n�o s�o permitidas neste servidor'
        ROLLBACK
        RETURN
    END
       

END
GO

ENABLE TRIGGER [trgBloquear_Login_Horario] ON ALL SERVER  
GO