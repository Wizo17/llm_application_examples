-- Requête complexe : Utilisation de plusieurs CTE
-- Cette requête analyse les performances des ventes par région, catégorie et période

WITH 
-- CTE 1 : Calcul des ventes mensuelles par région
RegionalSales AS (
    SELECT 
        R.RegionID,
        R.RegionName,
        YEAR(O.OrderDate) AS OrderYear,
        MONTH(O.OrderDate) AS OrderMonth,
        SUM(OD.Quantity * OD.UnitPrice) AS MonthlySales
    FROM 
        Orders O
        JOIN Customers C ON O.CustomerID = C.CustomerID
        JOIN Regions R ON C.RegionID = R.RegionID
        JOIN OrderDetails OD ON O.OrderID = OD.OrderID
    WHERE 
        O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        R.RegionID,
        R.RegionName,
        YEAR(O.OrderDate),
        MONTH(O.OrderDate)
),

-- CTE 2 : Calcul des ventes par catégorie
CategorySales AS (
    SELECT 
        C.CategoryID,
        C.CategoryName,
        R.RegionID,
        YEAR(O.OrderDate) AS OrderYear,
        MONTH(O.OrderDate) AS OrderMonth,
        SUM(OD.Quantity * OD.UnitPrice) AS MonthlyCategorySales
    FROM 
        Orders O
        JOIN Customers CU ON O.CustomerID = CU.CustomerID
        JOIN Regions R ON CU.RegionID = R.RegionID
        JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        JOIN Products P ON OD.ProductID = P.ProductID
        JOIN Categories C ON P.CategoryID = C.CategoryID
    WHERE 
        O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        C.CategoryID,
        C.CategoryName,
        R.RegionID,
        YEAR(O.OrderDate),
        MONTH(O.OrderDate)
),

-- CTE 3 : Calcul des statistiques régionales
RegionalStats AS (
    SELECT 
        RegionID,
        RegionName,
        AVG(MonthlySales) AS AvgMonthlySales,
        MAX(MonthlySales) AS MaxMonthlySales,
        MIN(MonthlySales) AS MinMonthlySales,
        STDEV(MonthlySales) AS StdDevSales
    FROM 
        RegionalSales
    GROUP BY 
        RegionID,
        RegionName
)

-- Requête principale combinant les CTE
SELECT 
    RS.RegionName,
    RS.OrderYear,
    RS.OrderMonth,
    FORMAT(DATEFROMPARTS(RS.OrderYear, RS.OrderMonth, 1), 'MMM yyyy') AS MonthYear,
    RS.MonthlySales,
    CAST(RS.MonthlySales AS DECIMAL(10,2)) / CAST(RST.AvgMonthlySales AS DECIMAL(10,2)) * 100 AS PercentOfAvgSales,
    CS.CategoryName,
    CS.MonthlyCategorySales,
    CAST(CS.MonthlyCategorySales AS DECIMAL(10,2)) / CAST(RS.MonthlySales AS DECIMAL(10,2)) * 100 AS CategoryPercentOfTotal
FROM 
    RegionalSales RS
    JOIN RegionalStats RST ON RS.RegionID = RST.RegionID
    JOIN CategorySales CS ON RS.RegionID = CS.RegionID 
                        AND RS.OrderYear = CS.OrderYear 
                        AND RS.OrderMonth = CS.OrderMonth
ORDER BY 
    RS.RegionName,
    RS.OrderYear,
    RS.OrderMonth,
    CS.MonthlyCategorySales DESC; 