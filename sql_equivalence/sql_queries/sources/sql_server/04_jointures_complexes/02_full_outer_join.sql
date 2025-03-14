-- Requête avec jointures complexes : Utilisation de FULL OUTER JOIN
-- Cette requête compare les ventes entre deux périodes

DECLARE @PeriodeCourante DATE = '2023-01-01';
DECLARE @PeriodePrecedente DATE = '2022-01-01';

WITH VentesPeriodeCourante AS (
    SELECT 
        P.ProductID,
        P.ProductName,
        C.CategoryID,
        C.CategoryName,
        SUM(OD.Quantity) AS QuantiteVendue,
        SUM(OD.Quantity * OD.UnitPrice) AS ChiffreAffaires
    FROM 
        Products P
        JOIN Categories C ON P.CategoryID = C.CategoryID
        JOIN OrderDetails OD ON P.ProductID = OD.ProductID
        JOIN Orders O ON OD.OrderID = O.OrderID
    WHERE 
        O.OrderDate BETWEEN @PeriodeCourante AND DATEADD(YEAR, 1, @PeriodeCourante) - 1
    GROUP BY 
        P.ProductID,
        P.ProductName,
        C.CategoryID,
        C.CategoryName
),
VentesPeriodePrecedente AS (
    SELECT 
        P.ProductID,
        P.ProductName,
        C.CategoryID,
        C.CategoryName,
        SUM(OD.Quantity) AS QuantiteVendue,
        SUM(OD.Quantity * OD.UnitPrice) AS ChiffreAffaires
    FROM 
        Products P
        JOIN Categories C ON P.CategoryID = C.CategoryID
        JOIN OrderDetails OD ON P.ProductID = OD.ProductID
        JOIN Orders O ON OD.OrderID = O.OrderID
    WHERE 
        O.OrderDate BETWEEN @PeriodePrecedente AND DATEADD(YEAR, 1, @PeriodePrecedente) - 1
    GROUP BY 
        P.ProductID,
        P.ProductName,
        C.CategoryID,
        C.CategoryName
)

SELECT 
    COALESCE(PC.ProductID, PP.ProductID) AS ProductID,
    COALESCE(PC.ProductName, PP.ProductName) AS ProductName,
    COALESCE(PC.CategoryName, PP.CategoryName) AS CategoryName,
    
    -- Données période courante
    PC.QuantiteVendue AS QuantiteCourante,
    PC.ChiffreAffaires AS CAcourant,
    
    -- Données période précédente
    PP.QuantiteVendue AS QuantitePrecedente,
    PP.ChiffreAffaires AS CAprecedent,
    
    -- Calcul des variations
    CASE 
        WHEN PP.QuantiteVendue IS NULL THEN 100 -- Nouveau produit
        WHEN PC.QuantiteVendue IS NULL THEN -100 -- Produit abandonné
        ELSE (PC.QuantiteVendue - PP.QuantiteVendue) / CAST(PP.QuantiteVendue AS FLOAT) * 100 
    END AS VariationQuantite,
    
    CASE 
        WHEN PP.ChiffreAffaires IS NULL THEN 100 -- Nouveau produit
        WHEN PC.ChiffreAffaires IS NULL THEN -100 -- Produit abandonné
        ELSE (PC.ChiffreAffaires - PP.ChiffreAffaires) / CAST(PP.ChiffreAffaires AS FLOAT) * 100 
    END AS VariationCA,
    
    -- Statut du produit
    CASE 
        WHEN PP.ProductID IS NULL THEN 'Nouveau produit'
        WHEN PC.ProductID IS NULL THEN 'Produit abandonné'
        WHEN PC.ChiffreAffaires > PP.ChiffreAffaires THEN 'En croissance'
        WHEN PC.ChiffreAffaires < PP.ChiffreAffaires THEN 'En déclin'
        ELSE 'Stable'
    END AS StatutProduit
FROM 
    VentesPeriodeCourante PC
    FULL OUTER JOIN VentesPeriodePrecedente PP ON PC.ProductID = PP.ProductID
ORDER BY 
    COALESCE(PC.CategoryName, PP.CategoryName),
    CASE 
        WHEN PP.ProductID IS NULL THEN 1 -- Nouveaux produits en premier
        WHEN PC.ProductID IS NULL THEN 3 -- Produits abandonnés en dernier
        ELSE 2 -- Produits existants au milieu
    END,
    COALESCE(PC.ChiffreAffaires, 0) DESC; 