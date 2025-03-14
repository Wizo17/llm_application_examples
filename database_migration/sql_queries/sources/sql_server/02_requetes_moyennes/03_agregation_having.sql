-- Requête moyenne : Agrégation avec GROUP BY et HAVING
-- Cette requête identifie les clients ayant passé plus de 5 commandes et dépensé plus de 10000€

SELECT 
    C.CustomerID,
    C.FirstName + ' ' + C.LastName AS CustomerName,
    COUNT(O.OrderID) AS TotalOrders,
    SUM(O.TotalAmount) AS TotalSpent
FROM 
    Customers C
    JOIN Orders O ON C.CustomerID = O.CustomerID
WHERE 
    O.OrderDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY 
    C.CustomerID,
    C.FirstName,
    C.LastName
HAVING 
    COUNT(O.OrderID) > 5
    AND SUM(O.TotalAmount) > 10000
ORDER BY 
    TotalSpent DESC; 