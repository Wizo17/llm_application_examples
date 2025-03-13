-- Requête moyenne 1: Jointure entre clients et commandes
-- Description: Cette requête récupère les informations des clients et leurs commandes
-- avec filtrage sur la période et le montant minimum

SELECT 
    c.ClientID,
    c.FirstName,
    c.LastName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM 
    Customers c
INNER JOIN 
    Orders o ON c.ClientID = o.ClientID
WHERE 
    o.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    AND o.TotalAmount > 1000
ORDER BY 
    o.TotalAmount DESC,
    o.OrderDate DESC; 