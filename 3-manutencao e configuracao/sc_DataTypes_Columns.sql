SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM dev1_wkpconfiguracao.INFORMATION_SCHEMA.COLUMNS
 WHERE DATA_TYPE IN ( 'text', 'ntext', 'image' )

SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM dev1_wkpdb1.INFORMATION_SCHEMA.COLUMNS
 WHERE DATA_TYPE IN ( 'text', 'ntext', 'image' )



/***
SELECT *,OBJECT_SCHEMA_NAME([object_id]),
       OBJECT_NAME([object_id]),
       name
FROM sys.columns
--WHERE system_type_id IN (35,99);
**/

