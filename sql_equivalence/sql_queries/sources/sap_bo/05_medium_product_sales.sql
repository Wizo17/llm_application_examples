-- Requête moyenne 2: Analyse des ventes de produits avec sous-requête
-- Description: Cette requête identifie les produits dont les ventes dépassent
-- la moyenne des ventes par catégorie

SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    SUM(od.Quantity * od.UnitPrice) AS TotalSales
FROM 
    Products p
INNER JOIN 
    OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN 
    Orders o ON od.OrderID = o.OrderID
WHERE 
    o.OrderDate >= '2023-01-01'
GROUP BY 
    p.ProductID, p.ProductName, p.CategoryName
HAVING 
    SUM(od.Quantity * od.UnitPrice) > (
        SELECT 
            AVG(CategorySales)
        FROM (
            SELECT 
                p2.CategoryName,
                SUM(od2.Quantity * od2.UnitPrice) AS CategorySales
            FROM 
                Products p2
            INNER JOIN 
                OrderDetails od2 ON p2.ProductID = od2.ProductID
            INNER JOIN 
                Orders o2 ON od2.OrderID = o2.OrderID
            WHERE 
                o2.OrderDate >= '2023-01-01'
                AND p2.CategoryName = p.CategoryName
            GROUP BY 
                p2.CategoryName
        ) AS CategoryAvg
    )
ORDER BY 
    p.CategoryName,
    TotalSales DESC; 