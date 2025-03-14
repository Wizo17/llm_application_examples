-- Requête avec jointures complexes 2: Analyse complète des clients
-- Description: Cette requête utilise des jointures complexes pour analyser
-- le comportement d'achat des clients et leurs préférences

SELECT
    c.ClientID,
    c.FirstName,
    c.LastName,
    c.Email,
    c.RegistrationDate,
    r.RegionName,
    r.Country,
    DATEDIFF(YEAR, c.BirthDate, GETDATE()) AS Age,
    c.Gender,
    c.CustomerSegment,
    
    -- Informations sur les commandes
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent,
    AVG(o.TotalAmount) AS AverageOrderValue,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS DaysSinceLastOrder,
    
    -- Préférences de produits
    (
        SELECT TOP 1 p.CategoryName
        FROM Orders o2
        INNER JOIN OrderDetails od ON o2.OrderID = od.OrderID
        INNER JOIN Products p ON od.ProductID = p.ProductID
        WHERE o2.ClientID = c.ClientID
        GROUP BY p.CategoryName
        ORDER BY COUNT(*) DESC, SUM(od.Quantity) DESC
    ) AS FavoriteCategory,
    
    -- Préférences de paiement
    (
        SELECT TOP 1 pm.PaymentMethod
        FROM Orders o3
        INNER JOIN PaymentTransactions pt ON o3.OrderID = pt.OrderID
        INNER JOIN PaymentMethods pm ON pt.PaymentMethodID = pm.PaymentMethodID
        WHERE o3.ClientID = c.ClientID
        GROUP BY pm.PaymentMethod
        ORDER BY COUNT(*) DESC
    ) AS PreferredPaymentMethod,
    
    -- Préférences de livraison
    (
        SELECT TOP 1 sm.ShippingMethod
        FROM Orders o4
        INNER JOIN ShippingDetails sd ON o4.OrderID = sd.OrderID
        INNER JOIN ShippingMethods sm ON sd.ShippingMethodID = sm.ShippingMethodID
        WHERE o4.ClientID = c.ClientID
        GROUP BY sm.ShippingMethod
        ORDER BY COUNT(*) DESC
    ) AS PreferredShippingMethod,
    
    -- Activité sur le site web
    COALESCE(ws.VisitCount, 0) AS WebsiteVisits,
    COALESCE(ws.AverageTimeOnSite, 0) AS AverageTimeOnSiteMinutes,
    COALESCE(ws.CartAbandonmentRate, 0) AS CartAbandonmentRate,
    
    -- Activité marketing
    COALESCE(me.EmailOpenRate, 0) AS EmailOpenRate,
    COALESCE(me.EmailClickRate, 0) AS EmailClickRate,
    
    -- Satisfaction client
    COALESCE(AVG(sr.SatisfactionScore), 0) AS AverageSatisfactionScore,
    COALESCE(COUNT(sr.ReviewID), 0) AS NumberOfReviews,
    
    -- Valeur client
    SUM(o.TotalAmount) / NULLIF(DATEDIFF(MONTH, c.RegistrationDate, GETDATE()), 0) AS MonthlyAverageSpend,
    CASE
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) <= 30 THEN 'Actif'
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) <= 90 THEN 'Récent'
        WHEN DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) <= 365 THEN 'En risque'
        ELSE 'Inactif'
    END AS CustomerStatus
FROM
    Customers c
LEFT JOIN
    Regions r ON c.RegionID = r.RegionID
LEFT JOIN
    Orders o ON c.ClientID = o.ClientID
LEFT JOIN
    CustomerAddresses ca ON c.ClientID = ca.ClientID AND ca.IsDefault = 'Y'
LEFT JOIN
    WebsiteStatistics ws ON c.ClientID = ws.ClientID
LEFT JOIN
    MarketingEffectiveness me ON c.ClientID = me.ClientID
LEFT JOIN
    SatisfactionReviews sr ON c.ClientID = sr.ClientID
LEFT JOIN
    LoyaltyProgram lp ON c.ClientID = lp.ClientID
LEFT JOIN
    CustomerSupport cs ON c.ClientID = cs.ClientID
WHERE
    c.IsActive = 'Y'
GROUP BY
    c.ClientID,
    c.FirstName,
    c.LastName,
    c.Email,
    c.RegistrationDate,
    r.RegionName,
    r.Country,
    c.BirthDate,
    c.Gender,
    c.CustomerSegment,
    ws.VisitCount,
    ws.AverageTimeOnSite,
    ws.CartAbandonmentRate,
    me.EmailOpenRate,
    me.EmailClickRate
ORDER BY
    TotalSpent DESC; 