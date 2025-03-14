-- Requête simple : Sélection de colonnes spécifiques avec filtrage
-- Cette requête récupère le nom, prénom et email des clients actifs

SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email
FROM 
    Customers
WHERE 
    IsActive = 1
ORDER BY 
    LastName ASC,
    FirstName ASC; 