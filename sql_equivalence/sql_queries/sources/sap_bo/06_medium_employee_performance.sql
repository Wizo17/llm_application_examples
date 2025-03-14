-- Requête moyenne 3: Analyse de la performance des employés
-- Description: Cette requête calcule les ventes totales par employé et par trimestre
-- avec comparaison au trimestre précédent

SELECT 
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    YEAR(o.OrderDate) AS Year,
    DATEPART(QUARTER, o.OrderDate) AS Quarter,
    SUM(o.TotalAmount) AS QuarterlySales,
    (
        SELECT SUM(o2.TotalAmount)
        FROM Orders o2
        WHERE o2.EmployeeID = e.EmployeeID
        AND YEAR(o2.OrderDate) = YEAR(o.OrderDate)
        AND DATEPART(QUARTER, o2.OrderDate) = DATEPART(QUARTER, o.OrderDate) - 1
    ) AS PreviousQuarterSales,
    CASE 
        WHEN (
            SELECT SUM(o2.TotalAmount)
            FROM Orders o2
            WHERE o2.EmployeeID = e.EmployeeID
            AND YEAR(o2.OrderDate) = YEAR(o.OrderDate)
            AND DATEPART(QUARTER, o2.OrderDate) = DATEPART(QUARTER, o.OrderDate) - 1
        ) > 0 
        THEN (SUM(o.TotalAmount) - (
            SELECT SUM(o2.TotalAmount)
            FROM Orders o2
            WHERE o2.EmployeeID = e.EmployeeID
            AND YEAR(o2.OrderDate) = YEAR(o.OrderDate)
            AND DATEPART(QUARTER, o2.OrderDate) = DATEPART(QUARTER, o.OrderDate) - 1
        )) / (
            SELECT SUM(o2.TotalAmount)
            FROM Orders o2
            WHERE o2.EmployeeID = e.EmployeeID
            AND YEAR(o2.OrderDate) = YEAR(o.OrderDate)
            AND DATEPART(QUARTER, o2.OrderDate) = DATEPART(QUARTER, o.OrderDate) - 1
        ) * 100
        ELSE NULL
    END AS GrowthPercentage
FROM 
    Employees e
INNER JOIN 
    Orders o ON e.EmployeeID = o.EmployeeID
WHERE 
    o.OrderDate BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY 
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    YEAR(o.OrderDate),
    DATEPART(QUARTER, o.OrderDate)
ORDER BY 
    e.EmployeeID,
    Year,
    Quarter; 