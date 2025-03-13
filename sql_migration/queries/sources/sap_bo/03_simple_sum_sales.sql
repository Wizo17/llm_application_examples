-- Requête simple 3: Calcul du total des ventes par mois
-- Description: Cette requête calcule le montant total des ventes pour chaque mois
-- de l'année 2023 et les trie chronologiquement

SELECT 
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS MonthlySales
FROM 
    Orders
WHERE 
    YEAR(OrderDate) = 2023
GROUP BY 
    MONTH(OrderDate)
ORDER BY 
    Month ASC; 