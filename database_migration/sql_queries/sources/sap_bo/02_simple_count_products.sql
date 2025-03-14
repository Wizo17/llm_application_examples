-- Requête simple 2: Comptage de produits par catégorie
-- Description: Cette requête compte le nombre de produits dans chaque catégorie
-- et les trie par quantité décroissante

SELECT 
    CategoryName,
    COUNT(*) AS ProductCount
FROM 
    Products
GROUP BY 
    CategoryName
ORDER BY 
    ProductCount DESC; 