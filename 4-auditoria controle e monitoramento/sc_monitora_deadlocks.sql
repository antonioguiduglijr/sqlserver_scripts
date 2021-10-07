--https://www.dirceuresende.com/blog/sql-server-como-gerar-um-monitoramento-de-historico-de-deadlocks-para-analise-de-falhas-em-rotinas/

USE dba_db
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF (OBJECT_ID('dbo.Historico_Deadlocks') IS NULL)
BEGIN

    CREATE TABLE dbo.Historico_Deadlocks (
		Seq    INT IDENTITY(1,1),
        Dt_Log DATETIME,
        Ds_Log XML,
		CONSTRAINT PK_Historico_Deadlocks PRIMARY KEY CLUSTERED ([Seq])
    );
	CREATE NONCLUSTERED INDEX [IX_Historico_Deadlocks] ON dbo.Historico_Deadlocks ( [Dt_Log] ASC);
END


DECLARE @Ultimo_Log DATETIME = ISNULL((SELECT MAX(Dt_Log) FROM [dba_db].dbo.Historico_Deadlocks WITH(NOLOCK)), '1900-01-01')

INSERT INTO dbo.Historico_Deadlocks
SELECT
    xed.value('@timestamp', 'datetime2(3)') as CreationDate,
    xed.query('.') AS XEvent
FROM
(
    SELECT 
        CAST([target_data] AS XML) AS TargetData
    FROM 
        sys.dm_xe_session_targets AS st
        INNER JOIN sys.dm_xe_sessions AS s ON s.[address] = st.event_session_address
    WHERE 
        s.[name] = N'system_health'
        AND st.target_name = N'ring_buffer'
) AS [Data]
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData (xed)
WHERE
    xed.value('@timestamp', 'datetime2(3)') > @Ultimo_Log
ORDER BY 
    CreationDate DESC


------ envia emails

DECLARE @Seq INT
DECLARE @cmd VARCHAR(1000)
DECLARE @data VARCHAR(50)
DECLARE @sub VARCHAR(100)
DECLARE @file VARCHAR(100)

DECLARE MS_CRS_C1 CURSOR FOR
SELECT --TOP 1 -- TESTE
       Seq, CONVERT(VARCHAR(40), Dt_Log, 121 ) AS Data 
  FROM [dba_db].dbo.Historico_Deadlocks 
 WHERE Dt_Log >= @Ultimo_Log

OPEN MS_CRS_C1
FETCH MS_CRS_C1 INTO @Seq, @data

WHILE @@FETCH_STATUS >= 0
BEGIN

	SET @cmd = 'SET NOCOUNT ON;SELECT Ds_Log FROM [dba_db].dbo.Historico_Deadlocks WHERE Seq = ' + STR(@Seq)
	SET @sub = '[SQLSERVER_PORTAL] Deadlock - '+@data
	SET @file = 'deadlock_'+@data+'.xml'

	EXEC msdb.dbo.sp_send_dbmail
		@profile_name    = 'Alertas',
		@from_address    = 'TAABR-Database.ADM@wolterskluwer.com',
		@recipients      = 'TAABR-Database.ADM@wolterskluwer.com', 
		@copy_recipients = 'pedro.braga@wolterskluwer.com;henrique.silva@wolterskluwer.com;priscila.basques@wolterskluwer.com;jonatas.trafaniuc@wolterskluwer.com;nilesh.chitale@wolterskluwer.com', 
		@subject         = @sub,
		@body            = 'Favor verificar deadlock anexo.',
		@query           = @cmd,
		@attach_query_result_as_file = 1,
		@query_attachment_filename = @file,
		--@query_result_header = 0,
		--@exclude_query_output = 1,
		@query_no_truncate = 1

	FETCH MS_CRS_C1 INTO @Seq, @data

END
DEALLOCATE MS_CRS_C1
GO


SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


