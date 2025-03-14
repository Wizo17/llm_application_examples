-- Requête avec sous-requêtes complexes : Sous-requêtes dans la clause FROM
-- Cette requête analyse les tendances de vente par trimestre et par région

SELECT 
    RegionData.RegionName,
    RegionData.Year,
    RegionData.Quarter,
    RegionData.QuarterName,
    RegionData.TotalSales,
    RegionData.TotalOrders,
    RegionData.TotalCustomers,
    RegionData.AvgOrderValue,
    
    -- Calcul de la croissance par rapport au trimestre précédent
    RegionData.TotalSales - PrevQuarter.TotalSales AS SalesGrowthFromPrevQuarter,
    CASE 
        WHEN PrevQuarter.TotalSales = 0 THEN NULL
        ELSE (RegionData.TotalSales - PrevQuarter.TotalSales) / PrevQuarter.TotalSales * 100 
    END AS SalesGrowthPctFromPrevQuarter,
    
    -- Calcul de la croissance par rapport au même trimestre de l'année précédente
    RegionData.TotalSales - PrevYearSameQuarter.TotalSales AS SalesGrowthFromPrevYear,
    CASE 
        WHEN PrevYearSameQuarter.TotalSales = 0 THEN NULL
        ELSE (RegionData.TotalSales - PrevYearSameQuarter.TotalSales) / PrevYearSameQuarter.TotalSales * 100 
    END AS SalesGrowthPctFromPrevYear,
    
    -- Part de marché par rapport aux ventes totales
    CASE 
        WHEN TotalSalesByQuarter.TotalSales = 0 THEN 0
        ELSE RegionData.TotalSales / TotalSalesByQuarter.TotalSales * 100 
    END AS MarketSharePct,
    
    -- Classement des régions par trimestre
    RegionRank.RegionRank,
    
    -- Top catégories pour cette région et ce trimestre
    TopCategories.TopCategoriesList
FROM 
    -- Sous-requête principale : données de vente par région et par trimestre
    (
        SELECT 
            R.RegionID,
            R.RegionName,
            YEAR(O.OrderDate) AS Year,
            DATEPART(QUARTER, O.OrderDate) AS Quarter,
            'Q' + CAST(DATEPART(QUARTER, O.OrderDate) AS VARCHAR) + ' ' + CAST(YEAR(O.OrderDate) AS VARCHAR) AS QuarterName,
            SUM(OD.Quantity * OD.UnitPrice) AS TotalSales,
            COUNT(DISTINCT O.OrderID) AS TotalOrders,
            COUNT(DISTINCT O.CustomerID) AS TotalCustomers,
            SUM(OD.Quantity * OD.UnitPrice) / COUNT(DISTINCT O.OrderID) AS AvgOrderValue
        FROM 
            Regions R
            JOIN Customers C ON R.RegionID = C.RegionID
            JOIN Orders O ON C.CustomerID = O.CustomerID
            JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        WHERE 
            O.OrderDate BETWEEN '2022-01-01' AND '2023-12-31'
        GROUP BY 
            R.RegionID,
            R.RegionName,
            YEAR(O.OrderDate),
            DATEPART(QUARTER, O.OrderDate)
    ) RegionData
    
    -- Sous-requête : données du trimestre précédent
    LEFT JOIN (
        SELECT 
            R.RegionID,
            YEAR(O.OrderDate) AS Year,
            DATEPART(QUARTER, O.OrderDate) AS Quarter,
            SUM(OD.Quantity * OD.UnitPrice) AS TotalSales
        FROM 
            Regions R
            JOIN Customers C ON R.RegionID = C.RegionID
            JOIN Orders O ON C.CustomerID = O.CustomerID
            JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        WHERE 
            O.OrderDate BETWEEN '2022-01-01' AND '2023-12-31'
        GROUP BY 
            R.RegionID,
            YEAR(O.OrderDate),
            DATEPART(QUARTER, O.OrderDate)
    ) PrevQuarter ON RegionData.RegionID = PrevQuarter.RegionID
                  AND (
                      (RegionData.Year = PrevQuarter.Year AND RegionData.Quarter = PrevQuarter.Quarter + 1)
                      OR
                      (RegionData.Year = PrevQuarter.Year + 1 AND RegionData.Quarter = 1 AND PrevQuarter.Quarter = 4)
                  )
    
    -- Sous-requête : données du même trimestre de l'année précédente
    LEFT JOIN (
        SELECT 
            R.RegionID,
            YEAR(O.OrderDate) AS Year,
            DATEPART(QUARTER, O.OrderDate) AS Quarter,
            SUM(OD.Quantity * OD.UnitPrice) AS TotalSales
        FROM 
            Regions R
            JOIN Customers C ON R.RegionID = C.RegionID
            JOIN Orders O ON C.CustomerID = O.CustomerID
            JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        WHERE 
            O.OrderDate BETWEEN '2022-01-01' AND '2023-12-31'
        GROUP BY 
            R.RegionID,
            YEAR(O.OrderDate),
            DATEPART(QUARTER, O.OrderDate)
    ) PrevYearSameQuarter ON RegionData.RegionID = PrevYearSameQuarter.RegionID
                          AND RegionData.Year = PrevYearSameQuarter.Year + 1
                          AND RegionData.Quarter = PrevYearSameQuarter.Quarter
    
    -- Sous-requête : total des ventes par trimestre (toutes régions confondues)
    JOIN (
        SELECT 
            YEAR(O.OrderDate) AS Year,
            DATEPART(QUARTER, O.OrderDate) AS Quarter,
            SUM(OD.Quantity * OD.UnitPrice) AS TotalSales
        FROM 
            Orders O
            JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        WHERE 
            O.OrderDate BETWEEN '2022-01-01' AND '2023-12-31'
        GROUP BY 
            YEAR(O.OrderDate),
            DATEPART(QUARTER, O.OrderDate)
    ) TotalSalesByQuarter ON RegionData.Year = TotalSalesByQuarter.Year
                          AND RegionData.Quarter = TotalSalesByQuarter.Quarter
    
    -- Sous-requête : classement des régions par trimestre
    JOIN (
        SELECT 
            RegionID,
            Year,
            Quarter,
            RANK() OVER (PARTITION BY Year, Quarter ORDER BY TotalSales DESC) AS RegionRank
        FROM (
            SELECT 
                R.RegionID,
                YEAR(O.OrderDate) AS Year,
                DATEPART(QUARTER, O.OrderDate) AS Quarter,
                SUM(OD.Quantity * OD.UnitPrice) AS TotalSales
            FROM 
                Regions R
                JOIN Customers C ON R.RegionID = C.RegionID
                JOIN Orders O ON C.CustomerID = O.CustomerID
                JOIN OrderDetails OD ON O.OrderID = OD.OrderID
            WHERE 
                O.OrderDate BETWEEN '2022-01-01' AND '2023-12-31'
            GROUP BY 
                R.RegionID,
                YEAR(O.OrderDate),
                DATEPART(QUARTER, O.OrderDate)
        ) RankedRegions
    ) RegionRank ON RegionData.RegionID = RegionRank.RegionID
                 AND RegionData.Year = RegionRank.Year
                 AND RegionData.Quarter = RegionRank.Quarter
    
    -- Sous-requête : top 3 catégories par région et par trimestre
    OUTER APPLY (
        SELECT STRING_AGG(CategoryInfo.CategoryName + ' (' + CAST(CategoryInfo.CategorySales AS VARCHAR) + ')', ', ') AS TopCategoriesList
        FROM (
            SELECT TOP 3
                C.CategoryName,
                SUM(OD.Quantity * OD.UnitPrice) AS CategorySales
            FROM 
                Categories C
                JOIN Products P ON C.CategoryID = P.CategoryID
                JOIN OrderDetails OD ON P.ProductID = OD.ProductID
                JOIN Orders O ON OD.OrderID = O.OrderID
                JOIN Customers CU ON O.CustomerID = CU.CustomerID
            WHERE 
                CU.RegionID = RegionData.RegionID
                AND YEAR(O.OrderDate) = RegionData.Year
                AND DATEPART(QUARTER, O.OrderDate) = RegionData.Quarter
            GROUP BY 
                C.CategoryID,
                C.CategoryName
            ORDER BY 
                CategorySales DESC
        ) CategoryInfo
    ) TopCategories
ORDER BY 
    RegionData.Year,
    RegionData.Quarter,
    RegionRank.RegionRank; 