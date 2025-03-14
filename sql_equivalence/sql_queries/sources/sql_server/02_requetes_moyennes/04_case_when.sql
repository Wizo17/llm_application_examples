-- Requête moyenne : Utilisation de CASE WHEN pour la logique conditionnelle
-- Cette requête catégorise les produits selon leur niveau de stock

SELECT 
    ProductID,
    ProductName,
    UnitPrice,
    UnitsInStock,
    CASE 
        WHEN UnitsInStock = 0 THEN 'Rupture de stock'
        WHEN UnitsInStock < ReorderLevel THEN 'Stock faible'
        WHEN UnitsInStock < ReorderLevel * 2 THEN 'Stock moyen'
        ELSE 'Stock suffisant'
    END AS StockStatus,
    CASE 
        WHEN Discontinued = 1 THEN 'Oui'
        ELSE 'Non'
    END AS Discontinued
FROM 
    Products
ORDER BY 
    CategoryID,
    ProductName; 