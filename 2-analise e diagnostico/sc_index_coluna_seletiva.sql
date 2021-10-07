--http://www.mcdbabrasil.com.br/modules.php?name=News&file=article&sid=176&newlang=english
-- Quanto mais próximo de 1, melhor


-- Verifica a seletividade da coluna ShipCountry'
SELECT  [Qtde. Registros] = COUNT(1), 
 [Reg. Distintos] = COUNT(DISTINCT ShipCountry),
 -- Quanto mais próximo de 1, melhor
 [Seletividade] = COUNT(DISTINCT ShipCountry)/CAST( COUNT(1) AS DEC(10,2)) 
FROM Orders



