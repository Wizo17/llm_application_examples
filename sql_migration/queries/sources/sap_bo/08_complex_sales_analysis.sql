-- Requête complexe 2: Analyse des ventes avec fonctions analytiques
-- Description: Cette requête utilise des fonctions analytiques pour analyser
-- les tendances de ventes par produit, région et période

SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    r.RegionName,
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    SUM(od.Quantity * od.UnitPrice) AS MonthlySales,
    
    -- Ventes cumulatives par produit et année
    SUM(SUM(od.Quantity * od.UnitPrice)) OVER (
        PARTITION BY p.ProductID, YEAR(o.OrderDate)
        ORDER BY MONTH(o.OrderDate)
        ROWS UNBOUNDED PRECEDING
    ) AS CumulativeSales,
    
    -- Moyenne mobile sur 3 mois
    AVG(SUM(od.Quantity * od.UnitPrice)) OVER (
        PARTITION BY p.ProductID, r.RegionName
        ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS ThreeMonthMovingAvg,
    
    -- Classement des produits par région et mois
    RANK() OVER (
        PARTITION BY r.RegionName, YEAR(o.OrderDate), MONTH(o.OrderDate)
        ORDER BY SUM(od.Quantity * od.UnitPrice) DESC
    ) AS ProductRankInRegion,
    
    -- Pourcentage des ventes totales par catégorie
    SUM(od.Quantity * od.UnitPrice) / SUM(SUM(od.Quantity * od.UnitPrice)) OVER (
        PARTITION BY p.CategoryName, YEAR(o.OrderDate), MONTH(o.OrderDate)
    ) * 100 AS PercentOfCategorySales,
    
    -- Différence avec le mois précédent
    SUM(od.Quantity * od.UnitPrice) - LAG(SUM(od.Quantity * od.UnitPrice), 1, 0) OVER (
        PARTITION BY p.ProductID, r.RegionName
        ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)
    ) AS SalesDiffFromPrevMonth,
    
    -- Croissance en pourcentage par rapport au mois précédent
    CASE 
        WHEN LAG(SUM(od.Quantity * od.UnitPrice), 1, 0) OVER (
            PARTITION BY p.ProductID, r.RegionName
            ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)
        ) = 0 THEN NULL
        ELSE (SUM(od.Quantity * od.UnitPrice) - LAG(SUM(od.Quantity * od.UnitPrice), 1, 0) OVER (
            PARTITION BY p.ProductID, r.RegionName
            ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)
        )) / LAG(SUM(od.Quantity * od.UnitPrice), 1, 0) OVER (
            PARTITION BY p.ProductID, r.RegionName
            ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)
        ) * 100
    END AS GrowthPercentage
FROM
    Products p
INNER JOIN
    OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN
    Orders o ON od.OrderID = o.OrderID
INNER JOIN
    Customers c ON o.ClientID = c.ClientID
INNER JOIN
    Regions r ON c.RegionID = r.RegionID
WHERE
    o.OrderDate BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    r.RegionName,
    YEAR(o.OrderDate),
    MONTH(o.OrderDate)
ORDER BY
    r.RegionName,
    p.CategoryName,
    Year,
    Month; 