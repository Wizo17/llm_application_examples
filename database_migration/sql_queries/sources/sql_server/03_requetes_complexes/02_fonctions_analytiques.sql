-- Requête complexe : Fonctions analytiques
-- Cette requête utilise des fonctions analytiques pour analyser les ventes par produit et catégorie

SELECT 
    C.CategoryName,
    P.ProductID,
    P.ProductName,
    SUM(OD.Quantity * OD.UnitPrice) AS ProductSales,
    
    -- Classement des produits par ventes au sein de leur catégorie
    ROW_NUMBER() OVER (PARTITION BY C.CategoryID ORDER BY SUM(OD.Quantity * OD.UnitPrice) DESC) AS SalesRank,
    
    -- Pourcentage des ventes du produit par rapport au total de sa catégorie
    SUM(OD.Quantity * OD.UnitPrice) / SUM(SUM(OD.Quantity * OD.UnitPrice)) OVER (PARTITION BY C.CategoryID) * 100 AS CategorySalesPercentage,
    
    -- Ventes cumulatives au sein de la catégorie
    SUM(SUM(OD.Quantity * OD.UnitPrice)) OVER (
        PARTITION BY C.CategoryID 
        ORDER BY SUM(OD.Quantity * OD.UnitPrice) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeCategorySales,
    
    -- Moyenne mobile sur 3 produits
    AVG(SUM(OD.Quantity * OD.UnitPrice)) OVER (
        PARTITION BY C.CategoryID 
        ORDER BY SUM(OD.Quantity * OD.UnitPrice) DESC
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS MovingAverage3Products
FROM 
    Products P
    JOIN Categories C ON P.CategoryID = C.CategoryID
    JOIN OrderDetails OD ON P.ProductID = OD.ProductID
    JOIN Orders O ON OD.OrderID = O.OrderID
WHERE 
    O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    C.CategoryID,
    C.CategoryName,
    P.ProductID,
    P.ProductName
ORDER BY 
    C.CategoryName,
    SalesRank; 