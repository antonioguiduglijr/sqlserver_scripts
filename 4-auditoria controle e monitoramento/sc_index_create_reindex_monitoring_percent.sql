--https://www.fabriciolima.net/blog/2018/09/11/queries-do-dia-a-dia-como-monitorar-o-percentual-de-execucao-na-criacao-ou-rebuild-de-um-indice/

-- Antes de criar um índice habilite o STATISTICS PROFILE:
SET STATISTICS PROFILE ON
GO
create nonclustered index NOME_INDEX on NOME_TABELA(Colunas...) WITH(...)
GO

-- O mesmo vale para desfragmentar um índice:
SET STATISTICS PROFILE ON
GO
alter index NOME_INDEX on NOME_TABELA  REBUILD
GO


-- Após iniciar o comando de criação ou desfragmentação do índice, em outra conexão, execute a query abaixo alterando o SPID no WHERE:
-- Acompanhar a criação ou desfragmentação do índice
SELECT node_id,physical_operator_name, SUM(row_count) row_count, 
  SUM(estimate_row_count) AS estimate_row_count, 
  CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count)  percent_completed
FROM sys.dm_exec_query_profiles   
WHERE session_id= (colocar o SPID da conexão que quer monitorar)
GROUP BY node_id,physical_operator_name  
ORDER BY node_id;
GO

