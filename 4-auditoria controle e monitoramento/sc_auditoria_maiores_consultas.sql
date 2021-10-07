https://www.dirceuresende.com/blog/sql-server-como-identificar-e-coletar-informacoes-de-consultas-demoradas-utilizando-trace-sql-server-profiler/

/*****************
O fluxo dessa rotina funciona da seguinte forma:

- Verifica se o trace já está ativo.
- Caso o trace esteja ativo, desativa o trace e fecha o arquivo
- Cria a tabela de histórico das consultas (caso não exista).
- Lê os dados do arquivo de trace e insere na tabela de histórico
- Ativa o recurso xp_cmdshell dinamicamente (caso não esteja ativado)
- Apaga o arquivo de trace
- Desativa o recurso xp_cmdshell dinamicamente (caso não estava ativado antes)
- Cria novamente o trace
- Ativa o trace recém criado

A ideia é que seja criado um Job que é executado a cada X minutos que execute todo esse processo, limpando o arquivo de trace e inserindo os dados coletados na tabela de histórico para que os DBA’s possam consultar os dados lidos do arquivo de trace.
*****************/

--------------------------------------------------------
-- Armazena os resultados do Trace na tabela
--------------------------------------------------------

DECLARE @Trace_Id INT, @Path VARCHAR(MAX)

SELECT 
    @Trace_Id = id,
    @Path = [path]
FROM 
    sys.traces
WHERE 
    [path] LIKE '%Querys_Demoradas.trc'


IF (@Trace_Id IS NOT NULL)
BEGIN


    -- Interrompe o rastreamento especificado.
    EXEC sys.sp_trace_setstatus
        @Trace_Id = @Trace_Id, 
        @status = 0


    -- Fecha o rastreamento especificado e exclui sua definição do servidor.
    EXEC sys.sp_trace_setstatus 
        @Trace_Id = @Trace_Id,
        @status = 2


    IF (OBJECT_ID('dbo.Historico_Query_Demorada') IS NULL)
    BEGIN

        CREATE TABLE [dbo].[Historico_Query_Demorada] (
            [TextData] [text] NULL,
            [NTUserName] [varchar] (128) NULL,
            [HostName] [varchar] (128) NULL,
            [ApplicationName] [varchar] (128) NULL,
            [LoginName] [varchar] (128) NULL,
            [SPID] [int] NULL,
            [Duration] [numeric] (15, 2) NULL,
            [StartTime] [datetime] NULL,
            [EndTime] [datetime] NULL,
            [Reads] [int] NULL,
            [Writes] [int] NULL,
            [CPU] [int] NULL,
            [ServerName] [varchar] (128) NULL,
            [DataBaseName] [varchar] (128) NULL,
            [RowCounts] [int] NULL,
            [SessionLoginName] [varchar] (128) NULL
        )
        WITH ( DATA_COMPRESSION = PAGE )

        CREATE CLUSTERED INDEX [SK01_Traces] ON [dbo].[Historico_Query_Demorada] ([StartTime]) WITH (FILLFACTOR=80, STATISTICS_NORECOMPUTE=ON, DATA_COMPRESSION = PAGE) ON [PRIMARY]
    
    END

    
    INSERT INTO dbo.Historico_Query_Demorada (
        Textdata, 
        NTUserName, 
        HostName, 
        ApplicationName, 
        LoginName, 
        SPID, 
        Duration, 
        Starttime,
        EndTime, 
        Reads,
        writes, 
        CPU, 
        Servername, 
        DatabaseName, 
        rowcounts, 
        SessionLoginName
    )
    SELECT
        Textdata,
        NTUserName,
        HostName,
        ApplicationName,
        LoginName,
        SPID,
        CAST(Duration / 1000 / 1000.00 AS NUMERIC(15, 2)) Duration,
        Starttime,
        EndTime,
        Reads,
        writes,
        CPU,
        Servername,
        DatabaseName,
        rowcounts,
        SessionLoginName
    FROM
        ::fn_trace_gettable(@Path, DEFAULT)
    WHERE
        Duration IS NOT NULL
        AND reads < 100000000
    ORDER BY
        Starttime;


    --------------------------------------------------------
    -- Apaga o arquivo de trace
    --------------------------------------------------------
    
    DECLARE @Fl_Xp_CmdShell_Ativado BIT = (SELECT (CASE WHEN CAST([value] AS VARCHAR(MAX)) = '1' THEN 1 ELSE 0 END) FROM sys.configurations WHERE [name] = 'xp_cmdshell')
 
    IF (@Fl_Xp_CmdShell_Ativado = 0)
    BEGIN
 
        EXECUTE SP_CONFIGURE 'show advanced options', 1;
        RECONFIGURE WITH OVERRIDE;
    
        EXEC sp_configure 'xp_cmdshell', 1;
        RECONFIGURE WITH OVERRIDE;
    
    END


    DECLARE @Cmd VARCHAR(4000) = 'del ' + @Path + ' /Q'
    EXEC sys.xp_cmdshell @Cmd


    IF (@Fl_Xp_CmdShell_Ativado = 0)
    BEGIN
 
        EXEC sp_configure 'xp_cmdshell', 0;
        RECONFIGURE WITH OVERRIDE;
 
        EXECUTE SP_CONFIGURE 'show advanced options', 0;
        RECONFIGURE WITH OVERRIDE;
 
    END


END



--------------------------------------------------------
-- Ativa o trace novamenmte
--------------------------------------------------------

DECLARE
    @resource INT,
    @maxfilesize BIGINT = 50,
    @on BIT = 1, -- Habilitado
    @bigintfilter BIGINT = (1000000 * 7) -- 7 segundos


-- Criação do trace
SET @Trace_Id = NULL

EXEC @resource = sys.sp_trace_create @Trace_Id OUTPUT, 0, N'C:\Querys_Demoradas', @maxfilesize, NULL 

IF (@resource = 0)
BEGIN

    EXEC sys.sp_trace_setevent @Trace_Id, 10, 1, @on  
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 6, @on  
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 8, @on  
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 10, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 11, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 12, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 13, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 14, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 15, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 16, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 17, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 18, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 26, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 35, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 40, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 48, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 10, 64, @on 

    EXEC sys.sp_trace_setevent @Trace_Id, 12, 1,  @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 6,  @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 8,  @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 10, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 11, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 12, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 13, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 14, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 15, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 16, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 17, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 18, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 26, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 35, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 40, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 48, @on 
    EXEC sys.sp_trace_setevent @Trace_Id, 12, 64, @on 


    -- Aqui é onde filtramos o tempo da query que irá cair no trace
    EXEC sys.sp_trace_setfilter @Trace_Id, 13, 0, 4, @bigintfilter -- O 4 significa >= @bigintfilter 


    -- Ativa o trace
    EXEC sys.sp_trace_setstatus @Trace_Id, 1


END

