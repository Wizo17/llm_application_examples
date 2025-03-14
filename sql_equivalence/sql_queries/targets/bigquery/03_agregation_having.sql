-- Query for BigQuery: Aggregation with GROUP BY and HAVING
-- This query identifies customers who placed more than 5 orders and spent more than €10,000

SELECT 
    C.CustomerID,
    CONCAT(C.FirstName, ' ', C.LastName) AS CustomerName,
    COUNT(O.OrderID) AS TotalOrders,
    SUM(O.TotalAmount) AS TotalSpent
FROM 
    Customers C
    JOIN Orders O ON C.CustomerID = O.CustomerID
WHERE 
    O.OrderDate >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
GROUP BY 
    C.CustomerID,
    C.FirstName,
    C.LastName
HAVING 
    COUNT(O.OrderID) > 5
    AND SUM(O.TotalAmount) > 10000
ORDER BY 
    TotalSpent DESC;