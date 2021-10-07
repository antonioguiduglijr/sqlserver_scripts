--http://www.dirceuresende.com/blog/como-descobrir-a-data-do-ultimo-acesso-a-uma-tabela-ou-view-e-execucao-da-uma-procedure-no-sql-server/
--data e hora da última execução de uma stored procedure

SELECT A.name AS [object_name],
       A.type_desc,
       MAX(B.last_execution_time) AS last_execution_time,
       ( SELECT create_date FROM sys.databases WHERE name = 'tempdb' ) AS since
  FROM sys.objects A 
  LEFT 
  JOIN ( sys.dm_exec_query_stats B CROSS APPLY sys.dm_exec_sql_text(B.sql_handle) C ) ON A.[object_id] = C.objectid
 WHERE A.type_desc LIKE '%_PROCEDURE'
   AND A.name = 'PRI_SP_GRAVARRETORNOEMAIL'
 GROUP BY A.name, A.type_desc
 ORDER BY 3 DESC, 1

