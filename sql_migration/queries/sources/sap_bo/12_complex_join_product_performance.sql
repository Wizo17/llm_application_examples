-- Requête avec jointures complexes 3: Analyse de la performance des produits
-- Description: Cette requête utilise des jointures complexes pour analyser
-- la performance des produits à travers différentes dimensions

SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    p.BrandName,
    p.LaunchDate,
    p.IsDiscontinued,
    
    -- Informations sur les ventes
    COALESCE(SUM(od.Quantity), 0) AS TotalUnitsSold,
    COALESCE(SUM(od.Quantity * od.UnitPrice), 0) AS TotalRevenue,
    COALESCE(SUM(od.Quantity * (od.UnitPrice - p.UnitCost)), 0) AS TotalProfit,
    COALESCE(SUM(od.Quantity * (od.UnitPrice - p.UnitCost)) / NULLIF(SUM(od.Quantity * od.UnitPrice), 0), 0) * 100 AS ProfitMarginPercentage,
    
    -- Performance par région
    (
        SELECT STRING_AGG(RegionSales.RegionName + ': ' + CAST(RegionSales.RegionRevenue AS VARCHAR), ', ')
        FROM (
            SELECT TOP 3
                r.RegionName,
                SUM(od2.Quantity * od2.UnitPrice) AS RegionRevenue
            FROM
                OrderDetails od2
            INNER JOIN
                Orders o2 ON od2.OrderID = o2.OrderID
            INNER JOIN
                Customers c ON o2.ClientID = c.ClientID
            INNER JOIN
                Regions r ON c.RegionID = r.RegionID
            WHERE
                od2.ProductID = p.ProductID
                AND o2.OrderDate >= DATEADD(YEAR, -1, GETDATE())
            GROUP BY
                r.RegionName
            ORDER BY
                RegionRevenue DESC
        ) AS RegionSales
    ) AS TopRegions,
    
    -- Performance par canal de vente
    (
        SELECT STRING_AGG(ChannelSales.ChannelName + ': ' + CAST(ChannelSales.ChannelRevenue AS VARCHAR), ', ')
        FROM (
            SELECT TOP 3
                sc.ChannelName,
                SUM(od3.Quantity * od3.UnitPrice) AS ChannelRevenue
            FROM
                OrderDetails od3
            INNER JOIN
                Orders o3 ON od3.OrderID = o3.OrderID
            INNER JOIN
                SalesChannels sc ON o3.ChannelID = sc.ChannelID
            WHERE
                od3.ProductID = p.ProductID
                AND o3.OrderDate >= DATEADD(YEAR, -1, GETDATE())
            GROUP BY
                sc.ChannelName
            ORDER BY
                ChannelRevenue DESC
        ) AS ChannelSales
    ) AS TopChannels,
    
    -- Informations sur les stocks
    p.CurrentStock,
    p.ReorderLevel,
    p.LeadTimeDays,
    CASE
        WHEN p.CurrentStock = 0 THEN 'Rupture de stock'
        WHEN p.CurrentStock <= p.ReorderLevel THEN 'Stock bas'
        ELSE 'Stock suffisant'
    END AS StockStatus,
    
    -- Informations sur les retours
    COALESCE(r.ReturnCount, 0) AS TotalReturns,
    CASE
        WHEN COALESCE(SUM(od.Quantity), 0) = 0 THEN 0
        ELSE COALESCE(r.ReturnCount, 0) / COALESCE(SUM(od.Quantity), 1) * 100
    END AS ReturnRatePercentage,
    
    -- Évaluations et avis
    COALESCE(pr.AverageRating, 0) AS AverageRating,
    COALESCE(pr.ReviewCount, 0) AS ReviewCount,
    
    -- Tendance des ventes
    COALESCE(
        (
            SELECT SUM(od4.Quantity)
            FROM OrderDetails od4
            INNER JOIN Orders o4 ON od4.OrderID = o4.OrderID
            WHERE od4.ProductID = p.ProductID
            AND o4.OrderDate BETWEEN DATEADD(MONTH, -1, GETDATE()) AND GETDATE()
        ), 0
    ) AS LastMonthSales,
    COALESCE(
        (
            SELECT SUM(od5.Quantity)
            FROM OrderDetails od5
            INNER JOIN Orders o5 ON od5.OrderID = o5.OrderID
            WHERE od5.ProductID = p.ProductID
            AND o5.OrderDate BETWEEN DATEADD(MONTH, -2, GETDATE()) AND DATEADD(MONTH, -1, GETDATE())
        ), 0
    ) AS PreviousMonthSales,
    
    -- Calcul de la tendance
    CASE
        WHEN (
            SELECT SUM(od5.Quantity)
            FROM OrderDetails od5
            INNER JOIN Orders o5 ON od5.OrderID = o5.OrderID
            WHERE od5.ProductID = p.ProductID
            AND o5.OrderDate BETWEEN DATEADD(MONTH, -2, GETDATE()) AND DATEADD(MONTH, -1, GETDATE())
        ) = 0 THEN 'Nouveau produit'
        WHEN (
            (
                SELECT SUM(od4.Quantity)
                FROM OrderDetails od4
                INNER JOIN Orders o4 ON od4.OrderID = o4.OrderID
                WHERE od4.ProductID = p.ProductID
                AND o4.OrderDate BETWEEN DATEADD(MONTH, -1, GETDATE()) AND GETDATE()
            ) - 
            (
                SELECT SUM(od5.Quantity)
                FROM OrderDetails od5
                INNER JOIN Orders o5 ON od5.OrderID = o5.OrderID
                WHERE od5.ProductID = p.ProductID
                AND o5.OrderDate BETWEEN DATEADD(MONTH, -2, GETDATE()) AND DATEADD(MONTH, -1, GETDATE())
            )
        ) / (
            SELECT SUM(od5.Quantity)
            FROM OrderDetails od5
            INNER JOIN Orders o5 ON od5.OrderID = o5.OrderID
            WHERE od5.ProductID = p.ProductID
            AND o5.OrderDate BETWEEN DATEADD(MONTH, -2, GETDATE()) AND DATEADD(MONTH, -1, GETDATE())
        ) * 100 > 10 THEN 'En hausse'
        WHEN (
            (
                SELECT SUM(od4.Quantity)
                FROM OrderDetails od4
                INNER JOIN Orders o4 ON od4.OrderID = o4.OrderID
                WHERE od4.ProductID = p.ProductID
                AND o4.OrderDate BETWEEN DATEADD(MONTH, -1, GETDATE()) AND GETDATE()
            ) - 
            (
                SELECT SUM(od5.Quantity)
                FROM OrderDetails od5
                INNER JOIN Orders o5 ON od5.OrderID = o5.OrderID
                WHERE od5.ProductID = p.ProductID
                AND o5.OrderDate BETWEEN DATEADD(MONTH, -2, GETDATE()) AND DATEADD(MONTH, -1, GETDATE())
            )
        ) / (
            SELECT SUM(od5.Quantity)
            FROM OrderDetails od5
            INNER JOIN Orders o5 ON od5.OrderID = o5.OrderID
            WHERE od5.ProductID = p.ProductID
            AND o5.OrderDate BETWEEN DATEADD(MONTH, -2, GETDATE()) AND DATEADD(MONTH, -1, GETDATE())
        ) * 100 < -10 THEN 'En baisse'
        ELSE 'Stable'
    END AS SalesTrend
FROM
    Products p
LEFT JOIN
    OrderDetails od ON p.ProductID = od.ProductID
LEFT JOIN
    Orders o ON od.OrderID = o.OrderID AND o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
LEFT JOIN
    (
        SELECT
            ProductID,
            COUNT(*) AS ReturnCount
        FROM
            ProductReturns
        WHERE
            ReturnDate >= DATEADD(YEAR, -1, GETDATE())
        GROUP BY
            ProductID
    ) r ON p.ProductID = r.ProductID
LEFT JOIN
    (
        SELECT
            ProductID,
            AVG(Rating) AS AverageRating,
            COUNT(*) AS ReviewCount
        FROM
            ProductReviews
        WHERE
            ReviewDate >= DATEADD(YEAR, -1, GETDATE())
        GROUP BY
            ProductID
    ) pr ON p.ProductID = pr.ProductID
LEFT JOIN
    Suppliers s ON p.PrimarySupplierID = s.SupplierID
LEFT JOIN
    ProductPromotions pp ON p.ProductID = pp.ProductID AND 
        GETDATE() BETWEEN pp.StartDate AND pp.EndDate
GROUP BY
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    p.BrandName,
    p.LaunchDate,
    p.IsDiscontinued,
    p.CurrentStock,
    p.ReorderLevel,
    p.LeadTimeDays,
    p.UnitCost,
    r.ReturnCount,
    pr.AverageRating,
    pr.ReviewCount
ORDER BY
    TotalRevenue DESC; 