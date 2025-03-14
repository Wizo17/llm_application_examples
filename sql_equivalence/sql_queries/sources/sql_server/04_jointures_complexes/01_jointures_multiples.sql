-- Requête avec jointures complexes : Utilisation de plusieurs types de jointures
-- Cette requête combine INNER JOIN, LEFT JOIN et RIGHT JOIN pour analyser les commandes et les produits

SELECT 
    P.ProductID,
    P.ProductName,
    C.CategoryName,
    S.SupplierName,
    COALESCE(SUM(OD.Quantity), 0) AS TotalQuantitySold,
    COALESCE(SUM(OD.Quantity * OD.UnitPrice), 0) AS TotalRevenue,
    COUNT(DISTINCT O.OrderID) AS NumberOfOrders,
    COUNT(DISTINCT CU.CustomerID) AS NumberOfCustomers,
    MAX(O.OrderDate) AS LastOrderDate
FROM 
    Products P
    INNER JOIN Categories C ON P.CategoryID = C.CategoryID
    INNER JOIN Suppliers S ON P.SupplierID = S.SupplierID
    LEFT JOIN OrderDetails OD ON P.ProductID = OD.ProductID
    LEFT JOIN Orders O ON OD.OrderID = O.OrderID
    LEFT JOIN Customers CU ON O.CustomerID = CU.CustomerID
WHERE 
    (O.OrderDate IS NULL OR O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31')
GROUP BY 
    P.ProductID,
    P.ProductName,
    C.CategoryName,
    S.SupplierName
ORDER BY 
    TotalRevenue DESC,
    P.ProductName;

-- Partie 2 : Produits jamais commandés
SELECT 
    P.ProductID,
    P.ProductName,
    C.CategoryName,
    S.SupplierName,
    P.UnitPrice,
    P.UnitsInStock
FROM 
    Products P
    INNER JOIN Categories C ON P.CategoryID = C.CategoryID
    INNER JOIN Suppliers S ON P.SupplierID = S.SupplierID
    LEFT JOIN OrderDetails OD ON P.ProductID = OD.ProductID
WHERE 
    OD.OrderDetailID IS NULL
ORDER BY 
    C.CategoryName,
    P.ProductName;

-- Partie 3 : Clients sans commandes
SELECT 
    CU.CustomerID,
    CU.FirstName + ' ' + CU.LastName AS CustomerName,
    CU.Email,
    CU.Phone,
    R.RegionName,
    CU.RegistrationDate
FROM 
    Customers CU
    LEFT JOIN Orders O ON CU.CustomerID = O.CustomerID
    INNER JOIN Regions R ON CU.RegionID = R.RegionID
WHERE 
    O.OrderID IS NULL
ORDER BY 
    CU.RegistrationDate DESC; 