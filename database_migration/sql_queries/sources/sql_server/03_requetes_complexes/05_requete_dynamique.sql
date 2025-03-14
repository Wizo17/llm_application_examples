-- Requête complexe : SQL dynamique
-- Cette requête utilise du SQL dynamique pour générer un rapport personnalisable

CREATE OR ALTER PROCEDURE GenerateCustomReport
    @StartDate DATE,
    @EndDate DATE,
    @GroupBy NVARCHAR(50),  -- 'Category', 'Region', 'Customer', 'Month', 'Quarter', 'Year'
    @SortBy NVARCHAR(50),   -- 'Sales', 'Quantity', 'OrderCount'
    @SortOrder NVARCHAR(4), -- 'ASC', 'DESC'
    @TopN INT = NULL,       -- Nombre de résultats à retourner (NULL = tous)
    @IncludeDetails BIT = 0 -- 0 = résumé uniquement, 1 = inclure les détails
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation des paramètres
    IF @StartDate > @EndDate
    BEGIN
        THROW 50001, 'La date de début doit être antérieure à la date de fin.', 1;
        RETURN;
    END
    
    IF @GroupBy NOT IN ('Category', 'Region', 'Customer', 'Month', 'Quarter', 'Year')
    BEGIN
        THROW 50002, 'Valeur de GroupBy non valide. Valeurs acceptées : Category, Region, Customer, Month, Quarter, Year', 1;
        RETURN;
    END
    
    IF @SortBy NOT IN ('Sales', 'Quantity', 'OrderCount')
    BEGIN
        THROW 50003, 'Valeur de SortBy non valide. Valeurs acceptées : Sales, Quantity, OrderCount', 1;
        RETURN;
    END
    
    IF @SortOrder NOT IN ('ASC', 'DESC')
    BEGIN
        THROW 50004, 'Valeur de SortOrder non valide. Valeurs acceptées : ASC, DESC', 1;
        RETURN;
    END
    
    -- Construire la clause SELECT
    DECLARE @SelectClause NVARCHAR(MAX);
    DECLARE @FromClause NVARCHAR(MAX);
    DECLARE @WhereClause NVARCHAR(MAX);
    DECLARE @GroupByClause NVARCHAR(MAX);
    DECLARE @OrderByClause NVARCHAR(MAX);
    DECLARE @TopClause NVARCHAR(100) = '';
    
    -- Clause WHERE commune
    SET @WhereClause = 'WHERE O.OrderDate BETWEEN @StartDate AND @EndDate';
    
    -- Clause FROM commune
    SET @FromClause = '
    FROM Orders O
    JOIN OrderDetails OD ON O.OrderID = OD.OrderID
    JOIN Products P ON OD.ProductID = P.ProductID
    JOIN Categories C ON P.CategoryID = C.CategoryID
    JOIN Customers CU ON O.CustomerID = CU.CustomerID
    JOIN Regions R ON CU.RegionID = R.RegionID';
    
    -- Construire la clause SELECT et GROUP BY en fonction de @GroupBy
    IF @GroupBy = 'Category'
    BEGIN
        SET @SelectClause = '
        SELECT 
            C.CategoryID,
            C.CategoryName AS GroupName';
        SET @GroupByClause = '
        GROUP BY 
            C.CategoryID,
            C.CategoryName';
    END
    ELSE IF @GroupBy = 'Region'
    BEGIN
        SET @SelectClause = '
        SELECT 
            R.RegionID,
            R.RegionName AS GroupName';
        SET @GroupByClause = '
        GROUP BY 
            R.RegionID,
            R.RegionName';
    END
    ELSE IF @GroupBy = 'Customer'
    BEGIN
        SET @SelectClause = '
        SELECT 
            CU.CustomerID,
            CU.FirstName + '' '' + CU.LastName AS GroupName';
        SET @GroupByClause = '
        GROUP BY 
            CU.CustomerID,
            CU.FirstName + '' '' + CU.LastName';
    END
    ELSE IF @GroupBy = 'Month'
    BEGIN
        SET @SelectClause = '
        SELECT 
            YEAR(O.OrderDate) AS OrderYear,
            MONTH(O.OrderDate) AS OrderMonth,
            FORMAT(DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1), ''MMM yyyy'') AS GroupName';
        SET @GroupByClause = '
        GROUP BY 
            YEAR(O.OrderDate),
            MONTH(O.OrderDate),
            FORMAT(DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1), ''MMM yyyy'')';
    END
    ELSE IF @GroupBy = 'Quarter'
    BEGIN
        SET @SelectClause = '
        SELECT 
            YEAR(O.OrderDate) AS OrderYear,
            DATEPART(QUARTER, O.OrderDate) AS OrderQuarter,
            ''Q'' + CAST(DATEPART(QUARTER, O.OrderDate) AS VARCHAR) + '' '' + CAST(YEAR(O.OrderDate) AS VARCHAR) AS GroupName';
        SET @GroupByClause = '
        GROUP BY 
            YEAR(O.OrderDate),
            DATEPART(QUARTER, O.OrderDate),
            ''Q'' + CAST(DATEPART(QUARTER, O.OrderDate) AS VARCHAR) + '' '' + CAST(YEAR(O.OrderDate) AS VARCHAR)';
    END
    ELSE IF @GroupBy = 'Year'
    BEGIN
        SET @SelectClause = '
        SELECT 
            YEAR(O.OrderDate) AS OrderYear,
            CAST(YEAR(O.OrderDate) AS VARCHAR) AS GroupName';
        SET @GroupByClause = '
        GROUP BY 
            YEAR(O.OrderDate),
            CAST(YEAR(O.OrderDate) AS VARCHAR)';
    END
    
    -- Ajouter les métriques communes
    SET @SelectClause = @SelectClause + ',
        COUNT(DISTINCT O.OrderID) AS OrderCount,
        SUM(OD.Quantity) AS TotalQuantity,
        SUM(OD.Quantity * OD.UnitPrice) AS TotalSales';
    
    -- Ajouter la clause TOP si nécessaire
    IF @TopN IS NOT NULL
    BEGIN
        SET @TopClause = 'TOP (@TopN) ';
    END
    
    -- Construire la clause ORDER BY
    IF @SortBy = 'Sales'
    BEGIN
        SET @OrderByClause = 'ORDER BY TotalSales ' + @SortOrder;
    END
    ELSE IF @SortBy = 'Quantity'
    BEGIN
        SET @OrderByClause = 'ORDER BY TotalQuantity ' + @SortOrder;
    END
    ELSE IF @SortBy = 'OrderCount'
    BEGIN
        SET @OrderByClause = 'ORDER BY OrderCount ' + @SortOrder;
    END
    
    -- Construire et exécuter la requête principale
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = 'SELECT ' + @TopClause + @SelectClause + @FromClause + @WhereClause + @GroupByClause + @OrderByClause;
    
    -- Exécuter la requête principale
    EXEC sp_executesql @SQL, 
        N'@StartDate DATE, @EndDate DATE, @TopN INT', 
        @StartDate, @EndDate, @TopN;
    
    -- Si les détails sont demandés, exécuter une requête supplémentaire
    IF @IncludeDetails = 1
    BEGIN
        DECLARE @DetailsSQL NVARCHAR(MAX);
        SET @DetailsSQL = '
        SELECT 
            O.OrderID,
            O.OrderDate,
            CU.CustomerID,
            CU.FirstName + '' '' + CU.LastName AS CustomerName,
            R.RegionName,
            P.ProductID,
            P.ProductName,
            C.CategoryName,
            OD.Quantity,
            OD.UnitPrice,
            OD.Quantity * OD.UnitPrice AS LineTotal
        FROM 
            Orders O
            JOIN OrderDetails OD ON O.OrderID = OD.OrderID
            JOIN Products P ON OD.ProductID = P.ProductID
            JOIN Categories C ON P.CategoryID = C.CategoryID
            JOIN Customers CU ON O.CustomerID = CU.CustomerID
            JOIN Regions R ON CU.RegionID = R.RegionID
        WHERE 
            O.OrderDate BETWEEN @StartDate AND @EndDate
        ORDER BY 
            O.OrderDate DESC,
            O.OrderID,
            P.ProductName';
        
        EXEC sp_executesql @DetailsSQL, 
            N'@StartDate DATE, @EndDate DATE', 
            @StartDate, @EndDate;
    END
END;

-- Exemple d'utilisation de la procédure
EXEC GenerateCustomReport 
    @StartDate = '2023-01-01',
    @EndDate = '2023-12-31',
    @GroupBy = 'Category',
    @SortBy = 'Sales',
    @SortOrder = 'DESC',
    @TopN = 5,
    @IncludeDetails = 0; 