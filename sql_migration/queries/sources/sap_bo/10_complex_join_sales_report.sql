-- Requête avec jointures complexes 1: Rapport de ventes détaillé
-- Description: Cette requête utilise plusieurs types de jointures pour générer
-- un rapport de ventes complet incluant les produits sans ventes

SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    c.CategoryDescription,
    s.SupplierID,
    s.SupplierName,
    s.Country AS SupplierCountry,
    r.RegionName,
    COALESCE(SUM(od.Quantity), 0) AS TotalQuantitySold,
    COALESCE(SUM(od.Quantity * od.UnitPrice), 0) AS TotalSalesAmount,
    COALESCE(AVG(od.UnitPrice), p.ListPrice) AS AverageSellingPrice,
    p.ListPrice AS CurrentListPrice,
    COALESCE(COUNT(DISTINCT o.OrderID), 0) AS NumberOfOrders,
    COALESCE(COUNT(DISTINCT o.ClientID), 0) AS NumberOfCustomers,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS DaysSinceLastOrder,
    p.CurrentStock,
    p.ReorderLevel,
    CASE
        WHEN p.CurrentStock <= p.ReorderLevel THEN 'Réapprovisionnement nécessaire'
        ELSE 'Stock suffisant'
    END AS StockStatus,
    CASE
        WHEN MAX(o.OrderDate) IS NULL THEN 'Jamais vendu'
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) > 90 THEN 'Inactif'
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) > 30 THEN 'Peu actif'
        ELSE 'Actif'
    END AS ProductStatus
FROM
    Products p
INNER JOIN
    Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN
    Suppliers s ON p.PrimarySupplierID = s.SupplierID
LEFT JOIN
    ProductRegionAvailability pra ON p.ProductID = pra.ProductID
LEFT JOIN
    Regions r ON pra.RegionID = r.RegionID
LEFT JOIN
    OrderDetails od ON p.ProductID = od.ProductID
LEFT JOIN
    Orders o ON od.OrderID = o.OrderID AND o.OrderDate BETWEEN DATEADD(MONTH, -12, GETDATE()) AND GETDATE()
LEFT JOIN
    Customers cust ON o.ClientID = cust.ClientID
LEFT JOIN
    PromotionalOffers po ON p.ProductID = po.ProductID AND 
        GETDATE() BETWEEN po.StartDate AND po.EndDate
LEFT JOIN
    ProductReviews pr ON p.ProductID = pr.ProductID
GROUP BY
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    c.CategoryDescription,
    s.SupplierID,
    s.SupplierName,
    s.Country,
    r.RegionName,
    p.ListPrice,
    p.CurrentStock,
    p.ReorderLevel
ORDER BY
    c.CategoryName,
    TotalSalesAmount DESC; 