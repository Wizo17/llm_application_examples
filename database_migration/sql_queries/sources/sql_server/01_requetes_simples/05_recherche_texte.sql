-- Requête simple : Recherche de texte avec LIKE
-- Cette requête recherche des produits dont le nom contient un terme spécifique

SELECT 
    ProductID,
    ProductName,
    UnitPrice,
    UnitsInStock
FROM 
    Products
WHERE 
    ProductName LIKE '%chocolat%'
    OR ProductName LIKE '%cacao%'
    OR Description LIKE '%chocolat%'
ORDER BY 
    UnitPrice DESC; 