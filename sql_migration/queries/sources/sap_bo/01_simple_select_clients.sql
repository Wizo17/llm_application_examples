-- Requête simple 1: Sélection de clients avec filtrage et tri
-- Description: Cette requête sélectionne les informations des clients actifs
-- et les trie par nom de famille

SELECT 
    ClientID,
    FirstName,
    LastName,
    Email,
    PhoneNumber,
    RegistrationDate
FROM 
    Customers
WHERE 
    IsActive = 'Y'
    AND RegistrationDate >= '2023-01-01'
ORDER BY 
    LastName ASC,
    FirstName ASC; 