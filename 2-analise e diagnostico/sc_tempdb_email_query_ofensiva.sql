--https://www.mssqltips.com/sqlservertip/3276/sql-server-alert-for-tempdb-growing-out-of-control/
-- 18/08/2021

DECLARE @xml NVARCHAR(MAX)DECLARE @body NVARCHAR(MAX)
SET @xml =CAST((
  SELECT TOP 5 --Change number accordingly
  su.session_id AS 'td','',
  ss.login_name AS 'td','', 
  rq.command AS 'td','',
  su.Task_Alloc AS 'td','',
  su.Task_Dealloc AS 'td','',
 --Find Offending Query Text:
  (SELECT SUBSTRING(text, rq.statement_start_offset/2 + 1,
   (CASE WHEN statement_end_offset = -1 
         THEN LEN(CONVERT(nvarchar(max),text)) * 2 
         ELSE statement_end_offset 
   END - rq.statement_start_offset)/2)
  FROM sys.dm_exec_sql_text(sql_handle)) AS 'td'
  FROM      
  (SELECT su.session_id, su.request_id,
   SUM(su.internal_objects_alloc_page_count + su.user_objects_alloc_page_count) AS Task_Alloc,
   SUM(su.internal_objects_dealloc_page_count + su.user_objects_dealloc_page_count) AS Task_Dealloc
  FROM sys.dm_db_task_space_usage AS su
  GROUP BY session_id, request_id) AS su, 
   sys.dm_exec_sessions AS ss, 
   sys.dm_exec_requests AS rq
  WHERE su.session_id = rq.session_id 
   AND(su.request_id = rq.request_id) 
   AND (ss.session_id = su.session_id)
   AND su.session_id > 50  --sessions 50 and below are system sessions and should not be killed
   AND su.session_id <> (SELECT @@SPID) --Eliminates current user session from results
  ORDER BY su.Task_Alloc DESC  --The largest "Task Allocation/Deallocation" is probably the query that is causing the db growth
FOR XML PATH ('tr'), ELEMENTS ) AS NVARCHAR(MAX))
--BODY OF EMAIL - Edit for your environment
SET @body ='<html><H1>Tempdb Large Query</H1>
<body bgcolor=white>The query below with the <u>highest task allocation 
and high task deallocation</u> is most likely growing the tempdb. NOTE: Please <b>do not kill system tasks</b> 
that may be showing up in the table below.
<U>Only kill the query that is being run by a user and has the highest task allocation/deallocation.</U><BR> 
<BR>
To stop the query from running, do the following:<BR>
<BR>
1. Open <b>SQL Server Management Studio</b><BR>
2. <b>Connect to database engine using Windows Authentication</b><BR>
3. Click on <b>"New Query"</b><BR>
4. Type <b>KILL [type session_id number from table below];</b> - It should look something like this:  KILL 537; <BR>
5. Hit the <b>F5</b> button to run the query<BR>
<BR>
This should kill the session/query that is growing the large query.  It will also kick the individual out of the application.<BR>
You have just stopped the growth of the tempdb, without having to restart SQL Services, and have the large-running query available for your review.
<BR>
<BR>
<table border = 2><tr><th>Session_ID</th><th>Login_Name</th><th>Command</th><th>Task_Alloc</th><th>Task_Dealloc</th><th>Query_Text</th></tr>' 
SET @body = @body + @xml +'</table></body></html>'

--Send email to recipients:
EXEC msdb.dbo.sp_send_dbmail
@recipients =N'antonio.guidugli@improve.com.br', --Insert the TO: email Address here
--@copy_recipients ='dba_Manager@domain.com', --Insert the CC: Address here; If multiple addresses, separate them by a comma (,)
@body = @body,@body_format ='HTML',
@importance ='High',
@subject ='THIS IS A TEST', --Provide a subject for the email
@profile_name = 'SQL_Profile01' --Database Mail profile here
