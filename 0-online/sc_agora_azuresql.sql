/***
Descri��o: Monitora status das conex�es no banco de dados - SQL 2005 / SQL 2008
Autor....: Antonio Guidugli Junior
Data.....: 22/01/2014
***/

EXEC sp_WhoIsActive @sort_order = '[start_time] ASC', @show_sleeping_spids = 0,
@output_column_list = '[dd%][session_id][block%][status][sql_text][database_name][login_name][hostname][program_name][wait_info][cpu%][temp%][reads%][writes%][physical%][%]' -- [sql_command][tasks][tran_log%][context%][query_plan][locks]
--EXEC sp_WhoIsActive @help = 1

/**

-- Page Life Expectancy (PLE) value for each NUMA node in current instance  (Query 40) (PLE by NUMA Node)
SELECT @@SERVERNAME AS [Server Name], [object_name], instance_name, cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Buffer Node%' -- Handles named instances
AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);


select * from sys.dm_exec_requests where session_id > 50

exec sp_usrinputbuffer 84
**/

SET NOCOUNT ON
GO


SELECT a.session_id,
       a.blocking_session_id as blocked_by,
       a.status,
       DATEDIFF(MI,a.start_time,GETDATE()) as Run_Min,
       --CONVERT(VARCHAR(2),DATEDIFF(HH,a.start_time,GETDATE()))+':'+CONVERT(VARCHAR(2),DATEDIFF(MI,a.start_time,GETDATE()))+':'+CONVERT(VARCHAR(2),DATEDIFF(SS,a.start_time,GETDATE())) as Run, --TEMPO DE EXECU��O EM MINUTOS
       a.database_id as [DB_ID],
       DB_NAME( a.database_id ) as [DB_Name],
       s.program_name, s.host_name, s.login_time, s.nt_user_name,
       a.cpu_time, a.logical_reads, a.reads, a.writes, a.row_count,
       a.command,
       a.wait_time, a.wait_type, a.wait_resource, 
       a.start_time, 
       a.total_elapsed_time as elapsed_time, 
       a.open_transaction_count as open_tran, a.percent_complete--, --a.granted_query_memory, a.executing_managed_code,
       --st.text, qp.query_plan
     FROM sys.dm_exec_requests                    a
     LEFT
     JOIN sys.dm_exec_sessions                    s ON s.session_id = a.session_id
    --CROSS
    --APPLY sys.dm_exec_sql_text( a.sql_handle )    st
    --CROSS 
    --APPLY sys.dm_exec_query_plan( a.plan_handle ) qp
    WHERE a.session_id <> @@SPID
	  --AND a.blocking_session_id = 99 
	  --AND a.session_id = 457
	  AND ( a.blocking_session_id <> 0 OR ( a.session_id IN ( SELECT blocking_session_id FROM sys.dm_exec_requests WHERE blocking_session_id <> 0 ) ) )
 ORDER BY a.blocking_session_id desc, a.session_id 
GO


--kill 99
--SELECT * FROM sys.dm_tran_locks 

/***
--- conteudo de cursor
SELECT c.session_id, c.properties, c.creation_time, c.is_open, t.text
  FROM sys.dm_exec_cursors (116) c --SPID
 CROSS 
 APPLY sys.dm_exec_sql_text (c.sql_handle) t 

--- conteudo de cursor
SELECT  *
  FROM sys.dm_exec_cursors (0)
***/

/***

SELECT DISTINCT	
       A.SPID,
       A.BLOCKED,
       --A.ECID,
       --A.WAITTIME AS WAITTIMEMS,
       DATEDIFF ( MI, A.LAST_BATCH, GETDATE() ) AS RUN_MIN, --TEMPO DE EXECU��O EM MINUTOS
       DATEDIFF ( SS, A.LAST_BATCH, GETDATE() ) AS RUN_SEG, --TEMPO DE EXECU��O EM MINUTOS

       A.STATUS,
       CASE WHEN A.STATUS = 'RUNNABLE'  THEN 1  
            WHEN A.STATUS = 'SUSPENDED' THEN 2
            ELSE                             9 
       END AS S_ORD,
       SUBSTRING( DB_NAME( A.DBID ), 1, 30 ) AS DBNAME,
       SUBSTRING( A.PROGRAM_NAME, 1, 35 ) AS PROGRAM_NAME,
       SUBSTRING( A.HOSTNAME    , 1, 25 ) AS HOSTNAME,
       SUBSTRING( A.LOGINAME    , 1, 25 ) AS LOGINNAME,
       A.DBID,
       A.CPU,
       SUBSTRING( CAST( A.PHYSICAL_IO AS VARCHAR(10)), 1, 10 ) AS PHYSICAL_IO,
       SUBSTRING( CONVERT( VARCHAR(24), A.LAST_BATCH , 113 ), 1, 24 ) AS LAST_BATCH,
       A.OPEN_TRAN,
       --A.MEMUSAGE--,
       --B.TEXTBUFFER,
       A.LOGIN_TIME       
     FROM MASTER..SYSPROCESSES  A (NOLOCK) 
    WHERE A.SPID > 50
      AND A.SPID <> @@SPID
      --AND A.dbid = DB_ID()
      --AND A.STATUS = 'RUNNABLE'
      --AND A.HOSTNAME = 'SBK006844                '
      --AND LEFT( ISNULL( B.USUARIO, '' ), 7 ) LIKE 'BRUNO%'
      --AND A.SPID = 455
      --AND ( A.SPID IN ( SELECT BLOCKED FROM MASTER..SYSPROCESSES (NOLOCK) WHERE BLOCKED <> 0 ) OR A.BLOCKED <> 0 )
      --AND a.loginame in ( 'sisSCM' ) --, 'siscodificacao' )
 --ORDER BY LEFT( ISNULL( B.USUARIO, '' ), 20 ) 
 --ORDER BY A.SPID DESC
 --ORDER BY A.STATUS, A.CPU DESC --4 DESC
 ORDER BY CASE WHEN A.STATUS = 'RUNNABLE'  THEN 1
               WHEN A.STATUS = 'SUSPENDED' THEN 2
               ELSE                             9
           END, A.CPU DESC --4 DESC
GO

--***/



/*********** BLOCKING MONITOR
--https://support.microsoft.com/en-us/kb/271509
--http://simplesqlserver.com/2013/05/21/blocking-capturing-and-monitoring/

SELECT tl.resource_type
    , database_name = DB_NAME(tl.resource_database_id)
    , assoc_entity_id = tl.resource_associated_entity_id
    , lock_req = tl.request_mode
    , waiter_sid = tl.request_session_id
    , wait_duration = wt.wait_duration_ms
    , wt.wait_type
    , waiter_batch = wait_st.text
    , waiter_stmt = substring(wait_st.text,er.statement_start_offset/2 + 1,
                abs(case when er.statement_end_offset = -1
                then len(convert(nvarchar(max), wait_st.text)) * 2
                else er.statement_end_offset end - er.statement_start_offset)/2 + 1)
    , waiter_host = es.host_name
    , waiter_user = es.login_name
    , blocker_sid = wt.blocking_session_id
    , blocker_stmt = block_st.text 
    , blocker_host = block_es.host_name
    , blocker_user = block_es.login_name
FROM sys.dm_tran_locks tl (nolock)
    INNER JOIN sys.dm_os_waiting_tasks wt (nolock) ON tl.lock_owner_address = wt.resource_address
    INNER JOIN sys.dm_os_tasks ot (nolock) ON tl.request_session_id = ot.session_id AND tl.request_request_id = ot.request_id AND tl.request_exec_context_id = ot.exec_context_id
    INNER JOIN sys.dm_exec_requests er (nolock) ON tl.request_session_id = er.session_id AND tl.request_request_id = er.request_id
    INNER JOIN sys.dm_exec_sessions es (nolock) ON tl.request_session_id = es.session_id
    LEFT JOIN sys.dm_exec_requests block_er (nolock) ON wt.blocking_session_id = block_er.session_id
    LEFT JOIN sys.dm_exec_sessions block_es (nolock) ON wt.blocking_session_id = block_es.session_id 
    CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) wait_st
    OUTER APPLY sys.dm_exec_sql_text(block_er.sql_handle) block_st


CREATE TABLE Blocking (
    BlockingID BigInt Identity(1,1) NOT NULL
    , resource_type NVarChar(60)
    , database_name SysName
    , assoc_entity_id BigInt
    , lock_req NVarChar(60)
    , wait_spid Int
    , wait_duration_ms Int
    , wait_type NVarChar(60)
    , wait_batch NVarChar(max)
    , wait_stmt NVarChar(max)
    , wait_host SysName
    , wait_user SysName
    , block_spid Int
    , block_stmt NVarChar(max)
    , block_host SysName
    , block_user SysName
    , DateAdded datetime NOT NULL DEFAULT (GetDate())
)
GO

CREATE UNIQUE CLUSTERED INDEX IX_Blocking_DateAdded_BlockingID_U_C ON Blocking
(
    DateAdded
    , BlockingID
) WITH (Fillfactor = 95)
GO

************/


