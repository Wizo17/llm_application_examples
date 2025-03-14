-- Requête simple : Filtrage par date
-- Cette requête récupère les commandes passées au cours du dernier mois

SELECT 
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount
FROM 
    Orders
WHERE 
    OrderDate >= DATEADD(MONTH, -1, GETDATE())
ORDER BY 
    OrderDate DESC; 