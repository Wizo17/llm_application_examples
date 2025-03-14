-- Requête avec sous-requêtes complexes : Sous-requêtes dans la clause WHERE
-- Cette requête identifie les clients VIP qui répondent à plusieurs critères complexes

SELECT 
    C.CustomerID,
    C.FirstName + ' ' + C.LastName AS CustomerName,
    C.Email,
    C.Phone,
    R.RegionName,
    C.RegistrationDate,
    CustomerStats.TotalOrders,
    CustomerStats.TotalSpent,
    CustomerStats.AvgOrderValue,
    CustomerStats.LastOrderDate,
    CustomerStats.DaysSinceLastOrder
FROM 
    Customers C
    JOIN Regions R ON C.RegionID = R.RegionID
    JOIN (
        SELECT 
            O.CustomerID,
            COUNT(O.OrderID) AS TotalOrders,
            SUM(O.TotalAmount) AS TotalSpent,
            AVG(O.TotalAmount) AS AvgOrderValue,
            MAX(O.OrderDate) AS LastOrderDate,
            DATEDIFF(DAY, MAX(O.OrderDate), GETDATE()) AS DaysSinceLastOrder
        FROM 
            Orders O
        WHERE 
            O.OrderDate >= DATEADD(YEAR, -2, GETDATE())
        GROUP BY 
            O.CustomerID
    ) CustomerStats ON C.CustomerID = CustomerStats.CustomerID
WHERE 
    -- Critère 1 : Clients ayant dépensé plus que la moyenne
    CustomerStats.TotalSpent > (
        SELECT AVG(TotalSpent)
        FROM (
            SELECT 
                O.CustomerID,
                SUM(O.TotalAmount) AS TotalSpent
            FROM 
                Orders O
            WHERE 
                O.OrderDate >= DATEADD(YEAR, -2, GETDATE())
            GROUP BY 
                O.CustomerID
        ) AvgSpentSubquery
    )
    
    -- Critère 2 : Clients ayant commandé au moins 5 fois
    AND CustomerStats.TotalOrders >= 5
    
    -- Critère 3 : Clients ayant commandé au cours des 90 derniers jours
    AND CustomerStats.DaysSinceLastOrder <= 90
    
    -- Critère 4 : Clients ayant acheté des produits dans au moins 3 catégories différentes
    AND (
        SELECT COUNT(DISTINCT P.CategoryID)
        FROM 
            Orders O
            JOIN OrderDetails OD ON O.OrderID = OD.OrderID
            JOIN Products P ON OD.ProductID = P.ProductID
        WHERE 
            O.CustomerID = C.CustomerID
            AND O.OrderDate >= DATEADD(YEAR, -2, GETDATE())
    ) >= 3
    
    -- Critère 5 : Clients ayant acheté au moins un produit premium (prix > 100)
    AND EXISTS (
        SELECT 1
        FROM 
            Orders O
            JOIN OrderDetails OD ON O.OrderID = OD.OrderID
            JOIN Products P ON OD.ProductID = P.ProductID
        WHERE 
            O.CustomerID = C.CustomerID
            AND P.UnitPrice > 100
            AND O.OrderDate >= DATEADD(YEAR, -2, GETDATE())
    )
    
    -- Critère 6 : Clients n'ayant jamais retourné de produits
    AND NOT EXISTS (
        SELECT 1
        FROM 
            Returns R
            JOIN Orders O ON R.OrderID = O.OrderID
        WHERE 
            O.CustomerID = C.CustomerID
    )
    
    -- Critère 7 : Clients dont la valeur moyenne des commandes est supérieure à la moyenne de leur région
    AND CustomerStats.AvgOrderValue > (
        SELECT AVG(RegionAvgOrderValue.AvgOrderValue)
        FROM (
            SELECT 
                CU.RegionID,
                O.CustomerID,
                AVG(O.TotalAmount) AS AvgOrderValue
            FROM 
                Customers CU
                JOIN Orders O ON CU.CustomerID = O.CustomerID
            WHERE 
                CU.RegionID = C.RegionID
                AND O.OrderDate >= DATEADD(YEAR, -2, GETDATE())
            GROUP BY 
                CU.RegionID,
                O.CustomerID
        ) RegionAvgOrderValue
    )
    
    -- Critère 8 : Clients ayant recommandé au moins un autre client
    AND EXISTS (
        SELECT 1
        FROM 
            Customers ReferredCustomer
        WHERE 
            ReferredCustomer.ReferredBy = C.CustomerID
    )
    
    -- Critère 9 : Clients ayant visité le site web au moins 10 fois au cours du dernier mois
    AND (
        SELECT COUNT(*)
        FROM 
            WebsiteVisits WV
        WHERE 
            WV.CustomerID = C.CustomerID
            AND WV.VisitDate >= DATEADD(MONTH, -1, GETDATE())
    ) >= 10
    
    -- Critère 10 : Clients ayant un panier moyen supérieur à 150% de leur premier achat
    AND CustomerStats.AvgOrderValue > (
        SELECT TOP 1 O.TotalAmount * 1.5
        FROM 
            Orders O
        WHERE 
            O.CustomerID = C.CustomerID
        ORDER BY 
            O.OrderDate ASC
    )
ORDER BY 
    CustomerStats.TotalSpent DESC,
    CustomerStats.TotalOrders DESC; 