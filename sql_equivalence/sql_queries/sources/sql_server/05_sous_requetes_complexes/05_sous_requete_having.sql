-- Requête avec sous-requêtes complexes : Sous-requêtes dans la clause HAVING
-- Cette requête identifie les catégories de produits performantes selon plusieurs critères

SELECT 
    C.CategoryID,
    C.CategoryName,
    C.Description,
    COUNT(DISTINCT P.ProductID) AS ProductCount,
    SUM(P.UnitsInStock) AS TotalStock,
    AVG(P.UnitPrice) AS AvgPrice,
    MIN(P.UnitPrice) AS MinPrice,
    MAX(P.UnitPrice) AS MaxPrice,
    SUM(SalesData.TotalQuantity) AS TotalQuantitySold,
    SUM(SalesData.TotalRevenue) AS TotalRevenue,
    AVG(SalesData.TotalRevenue / NULLIF(SalesData.TotalQuantity, 0)) AS AvgRevenuePerUnit,
    COUNT(DISTINCT SalesData.CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT SalesData.OrderID) AS OrderCount
FROM 
    Categories C
    JOIN Products P ON C.CategoryID = P.CategoryID
    LEFT JOIN (
        SELECT 
            P.ProductID,
            P.CategoryID,
            O.OrderID,
            O.CustomerID,
            SUM(OD.Quantity) AS TotalQuantity,
            SUM(OD.Quantity * OD.UnitPrice) AS TotalRevenue
        FROM 
            Products P
            JOIN OrderDetails OD ON P.ProductID = OD.ProductID
            JOIN Orders O ON OD.OrderID = O.OrderID
        WHERE 
            O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
        GROUP BY 
            P.ProductID,
            P.CategoryID,
            O.OrderID,
            O.CustomerID
    ) SalesData ON P.ProductID = SalesData.ProductID
GROUP BY 
    C.CategoryID,
    C.CategoryName,
    C.Description
HAVING 
    -- Critère 1 : Catégories avec plus de produits que la moyenne
    COUNT(DISTINCT P.ProductID) > (
        SELECT AVG(ProductCount)
        FROM (
            SELECT 
                COUNT(DISTINCT ProductID) AS ProductCount
            FROM 
                Products
            GROUP BY 
                CategoryID
        ) AvgProductsPerCategory
    )
    
    -- Critère 2 : Catégories avec un chiffre d'affaires supérieur à la moyenne
    AND SUM(SalesData.TotalRevenue) > (
        SELECT AVG(CategoryRevenue)
        FROM (
            SELECT 
                P.CategoryID,
                SUM(OD.Quantity * OD.UnitPrice) AS CategoryRevenue
            FROM 
                Products P
                JOIN OrderDetails OD ON P.ProductID = OD.ProductID
                JOIN Orders O ON OD.OrderID = O.OrderID
            WHERE 
                O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            GROUP BY 
                P.CategoryID
        ) AvgRevenuePerCategory
    )
    
    -- Critère 3 : Catégories avec un taux de croissance positif par rapport à l'année précédente
    AND (
        SUM(CASE WHEN YEAR(O.OrderDate) = 2023 THEN OD.Quantity * OD.UnitPrice ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN YEAR(O.OrderDate) = 2022 THEN OD.Quantity * OD.UnitPrice ELSE 0 END), 0)
    ) > 1.0
    FROM 
        Categories C
        JOIN Products P ON C.CategoryID = P.CategoryID
        JOIN OrderDetails OD ON P.ProductID = OD.ProductID
        JOIN Orders O ON OD.OrderID = O.OrderID
    WHERE 
        O.OrderDate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        C.CategoryID
    )
    
    -- Critère 4 : Catégories avec une marge bénéficiaire moyenne supérieure à 30%
    AND (
        SELECT AVG((P.UnitPrice - P.UnitCost) / NULLIF(P.UnitPrice, 0) * 100)
        FROM Products P
        WHERE P.CategoryID = C.CategoryID
    ) > 30
    
    -- Critère 5 : Catégories avec au moins un produit dans le top 10 des ventes
    AND EXISTS (
        SELECT 1
        FROM (
            SELECT TOP 10
                P.ProductID
            FROM 
                Products P
                JOIN OrderDetails OD ON P.ProductID = OD.ProductID
                JOIN Orders O ON OD.OrderID = O.OrderID
            WHERE 
                O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            GROUP BY 
                P.ProductID
            ORDER BY 
                SUM(OD.Quantity * OD.UnitPrice) DESC
        ) Top10Products
        JOIN Products P ON Top10Products.ProductID = P.ProductID
        WHERE P.CategoryID = C.CategoryID
    )
    
    -- Critère 6 : Catégories avec un taux de rotation du stock supérieur à la moyenne
    AND (
        SUM(SalesData.TotalQuantity) / NULLIF(SUM(P.UnitsInStock), 0)
    ) > (
        SELECT AVG(StockTurnover)
        FROM (
            SELECT 
                P.CategoryID,
                SUM(OD.Quantity) / NULLIF(SUM(P.UnitsInStock), 0) AS StockTurnover
            FROM 
                Products P
                JOIN OrderDetails OD ON P.ProductID = OD.ProductID
                JOIN Orders O ON OD.OrderID = O.OrderID
            WHERE 
                O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            GROUP BY 
                P.CategoryID
        ) AvgStockTurnover
    )
    
    -- Critère 7 : Catégories avec un nombre de clients uniques supérieur à la moyenne
    AND COUNT(DISTINCT SalesData.CustomerID) > (
        SELECT AVG(UniqueCustomers)
        FROM (
            SELECT 
                P.CategoryID,
                COUNT(DISTINCT O.CustomerID) AS UniqueCustomers
            FROM 
                Products P
                JOIN OrderDetails OD ON P.ProductID = OD.ProductID
                JOIN Orders O ON OD.OrderID = O.OrderID
            WHERE 
                O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            GROUP BY 
                P.CategoryID
        ) AvgUniqueCustomers
    )
ORDER BY 
    TotalRevenue DESC,
    UniqueCustomers DESC; 