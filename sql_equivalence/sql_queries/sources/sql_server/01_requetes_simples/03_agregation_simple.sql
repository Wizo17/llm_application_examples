-- Requête simple : Agrégation simple
-- Cette requête calcule le total des ventes par catégorie de produit

SELECT 
    CategoryName,
    COUNT(OrderID) AS TotalOrders,
    SUM(Quantity) AS TotalQuantity,
    SUM(Quantity * UnitPrice) AS TotalRevenue
FROM 
    Products P
    JOIN OrderDetails OD ON P.ProductID = OD.ProductID
    JOIN Categories C ON P.CategoryID = C.CategoryID
GROUP BY 
    CategoryName
ORDER BY 
    TotalRevenue DESC; 