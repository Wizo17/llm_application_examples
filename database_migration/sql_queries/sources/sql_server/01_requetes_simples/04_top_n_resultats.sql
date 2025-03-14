-- Requête simple : Utilisation de TOP pour limiter les résultats
-- Cette requête récupère les 10 produits les plus vendus

SELECT TOP 10
    P.ProductName,
    SUM(OD.Quantity) AS TotalQuantitySold
FROM 
    Products P
    JOIN OrderDetails OD ON P.ProductID = OD.ProductID
GROUP BY 
    P.ProductName
ORDER BY 
    TotalQuantitySold DESC; 