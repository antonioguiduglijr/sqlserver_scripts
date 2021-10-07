--http://www.dirceuresende.com/blog/como-descobrir-a-data-do-ultimo-acesso-a-uma-tabela-ou-view-e-execucao-da-uma-procedure-no-sql-server/
--data e hora do último acesso de uma tabela ou view

SELECT
    A.name AS [object_name],
    A.type_desc,
    C.name AS index_name,
    (
        SELECT MAX(Ultimo_Acesso)
        FROM (VALUES (B.last_user_seek),(B.last_user_scan),(B.last_user_lookup),(B.last_user_update)) AS DataAcesso(Ultimo_Acesso)
    ) AS last_access,
    B.last_user_seek,
    B.last_user_scan,
    B.last_user_lookup,
    B.last_user_update,
    NULLIF(
        (CASE WHEN B.last_user_seek IS NOT NULL THEN 'Seek, ' ELSE '' END) +
        (CASE WHEN B.last_user_scan IS NOT NULL THEN 'Scan, ' ELSE '' END) +
        (CASE WHEN B.last_user_lookup IS NOT NULL THEN 'Lookup, ' ELSE '' END) +
        (CASE WHEN B.last_user_update IS NOT NULL THEN 'Update, ' ELSE '' END)
    , '') AS operations
FROM
    msdb.sys.objects					A
    LEFT JOIN msdb.sys.dm_db_index_usage_stats	        B	ON	B.[object_id] = A.[object_id]
    LEFT JOIN msdb.sys.indexes				C	ON	C.index_id = B.index_id AND C.[object_id] = B.[object_id]
WHERE
    A.type_desc IN ('VIEW', 'USER_TABLE')
ORDER BY
    A.name,
    B.index_id
	