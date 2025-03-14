-- Requête moyenne : Jointures multiples
-- Cette requête récupère les détails des commandes avec les informations clients et produits

SELECT 
    O.OrderID,
    O.OrderDate,
    C.CustomerID,
    C.FirstName + ' ' + C.LastName AS CustomerName,
    P.ProductName,
    OD.Quantity,
    OD.UnitPrice,
    (OD.Quantity * OD.UnitPrice) AS LineTotal
FROM 
    Orders O
    INNER JOIN Customers C ON O.CustomerID = C.CustomerID
    INNER JOIN OrderDetails OD ON O.OrderID = OD.OrderID
    INNER JOIN Products P ON OD.ProductID = P.ProductID
WHERE 
    O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    O.OrderDate DESC,
    O.OrderID,
    P.ProductName; 