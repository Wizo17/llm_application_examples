-- Requête moyenne : Sous-requête simple
-- Cette requête trouve les produits dont le prix est supérieur à la moyenne

SELECT 
    ProductID,
    ProductName,
    CategoryName,
    UnitPrice
FROM 
    Products P
    JOIN Categories C ON P.CategoryID = C.CategoryID
WHERE 
    UnitPrice > (
        SELECT AVG(UnitPrice) 
        FROM Products
    )
ORDER BY 
    UnitPrice DESC,
    CategoryName,
    ProductName; 