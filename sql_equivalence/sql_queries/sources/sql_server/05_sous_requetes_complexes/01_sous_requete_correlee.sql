-- Requête avec sous-requêtes complexes : Sous-requête corrélée
-- Cette requête identifie les produits dont les ventes sont supérieures à la moyenne de leur catégorie

SELECT 
    P.ProductID,
    P.ProductName,
    C.CategoryName,
    P.UnitPrice,
    SalesStats.TotalQuantity,
    SalesStats.TotalRevenue,
    (
        -- Sous-requête corrélée : moyenne des ventes pour la catégorie de ce produit
        SELECT AVG(SubStats.TotalRevenue)
        FROM (
            SELECT 
                SubP.ProductID,
                SUM(OD.Quantity * OD.UnitPrice) AS TotalRevenue
            FROM 
                Products SubP
                JOIN OrderDetails OD ON SubP.ProductID = OD.ProductID
                JOIN Orders O ON OD.OrderID = O.OrderID
            WHERE 
                SubP.CategoryID = P.CategoryID
                AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            GROUP BY 
                SubP.ProductID
        ) SubStats
    ) AS CategoryAverageRevenue,
    
    -- Pourcentage par rapport à la moyenne de la catégorie
    (SalesStats.TotalRevenue / 
        NULLIF((
            SELECT AVG(SubStats.TotalRevenue)
            FROM (
                SELECT 
                    SubP.ProductID,
                    SUM(OD.Quantity * OD.UnitPrice) AS TotalRevenue
                FROM 
                    Products SubP
                    JOIN OrderDetails OD ON SubP.ProductID = OD.ProductID
                    JOIN Orders O ON OD.OrderID = O.OrderID
                WHERE 
                    SubP.CategoryID = P.CategoryID
                    AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
                GROUP BY 
                    SubP.ProductID
            ) SubStats
        ), 0)
    ) * 100 AS PercentOfCategoryAverage,
    
    -- Classement du produit dans sa catégorie
    (
        SELECT COUNT(*) + 1
        FROM (
            SELECT 
                SubP.ProductID,
                SUM(OD.Quantity * OD.UnitPrice) AS TotalRevenue
            FROM 
                Products SubP
                JOIN OrderDetails OD ON SubP.ProductID = OD.ProductID
                JOIN Orders O ON OD.OrderID = O.OrderID
            WHERE 
                SubP.CategoryID = P.CategoryID
                AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            GROUP BY 
                SubP.ProductID
        ) BetterProducts
        WHERE BetterProducts.TotalRevenue > SalesStats.TotalRevenue
    ) AS CategoryRank
FROM 
    Products P
    JOIN Categories C ON P.CategoryID = C.CategoryID
    JOIN (
        SELECT 
            OD.ProductID,
            SUM(OD.Quantity) AS TotalQuantity,
            SUM(OD.Quantity * OD.UnitPrice) AS TotalRevenue
        FROM 
            OrderDetails OD
            JOIN Orders O ON OD.OrderID = O.OrderID
        WHERE 
            O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
        GROUP BY 
            OD.ProductID
    ) SalesStats ON P.ProductID = SalesStats.ProductID
WHERE 
    -- Filtrer uniquement les produits dont les ventes sont supérieures à la moyenne de leur catégorie
    SalesStats.TotalRevenue > (
        SELECT AVG(SubStats.TotalRevenue)
        FROM (
            SELECT 
                SubP.ProductID,
                SUM(SubOD.Quantity * SubOD.UnitPrice) AS TotalRevenue
            FROM 
                Products SubP
                JOIN OrderDetails SubOD ON SubP.ProductID = SubOD.ProductID
                JOIN Orders SubO ON SubOD.OrderID = SubO.OrderID
            WHERE 
                SubP.CategoryID = P.CategoryID
                AND SubO.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            GROUP BY 
                SubP.ProductID
        ) SubStats
    )
ORDER BY 
    C.CategoryName,
    CategoryRank; 