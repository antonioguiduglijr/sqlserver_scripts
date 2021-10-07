-- https://sqlnalata.wordpress.com/2016/08/25/analisando-deadlocks-no-sql-server/
--- ver deadlocks

--- SQL 2012 e superiores
SELECT XEvent.query('(event/data[@name="xml_report"]/value/deadlock)[1]') as DeadLockGraph ,
XEvent.value('(event/@timestamp)[1]', 'datetime2') as [timestamp]
FROM
(
SELECT XEvent.query('.') AS XEvent
FROM
(
SELECT CAST(target_data AS XML) AS TargetData
FROM sys.dm_xe_session_targets st
INNER JOIN sys.dm_xe_sessions s
ON s.address = st.event_session_address
WHERE s.name = 'system_health'
AND st.target_name = 'ring_buffer'
)  AS Data
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData (XEvent)
) As src;


/************
--- SQL 2008
SELECT CAST(XEvent.value('(event/data/value)[1]', 'varchar(max)') AS XML) as DeadlockGraph,
XEvent.value('(/event/@timestamp)[1]', 'datetime2') as [Timestamp]
FROM
(
SELECT XEvent.query('.') AS XEvent
FROM
(
SELECT CAST(target_data AS XML) AS TargetData
FROM sys.dm_xe_session_targets st
INNER JOIN sys.dm_xe_sessions s
ON s.address = st.event_session_address
WHERE s.name = 'system_health'
AND st.target_name = 'ring_buffer') as Data
CROSS APPLY TargetData.nodes ('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData (XEvent)
)
AS src;
********************/
