-- Requête avec sous-requêtes complexes 2: Segmentation avancée des clients
-- Description: Cette requête utilise des sous-requêtes corrélées pour segmenter
-- les clients selon plusieurs dimensions comportementales

SELECT
    c.ClientID,
    c.FirstName,
    c.LastName,
    c.Email,
    c.RegistrationDate,
    
    -- Récence (jours depuis le dernier achat)
    COALESCE(
        (
            SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
            FROM Orders o
            WHERE o.ClientID = c.ClientID
        ), 
        DATEDIFF(DAY, c.RegistrationDate, GETDATE())
    ) AS DaysSinceLastPurchase,
    
    -- Fréquence (nombre de commandes)
    (
        SELECT COUNT(*)
        FROM Orders o
        WHERE o.ClientID = c.ClientID
    ) AS OrderCount,
    
    -- Valeur monétaire (montant total dépensé)
    (
        SELECT COALESCE(SUM(o.TotalAmount), 0)
        FROM Orders o
        WHERE o.ClientID = c.ClientID
    ) AS TotalSpent,
    
    -- Valeur moyenne des commandes
    (
        SELECT COALESCE(AVG(o.TotalAmount), 0)
        FROM Orders o
        WHERE o.ClientID = c.ClientID
    ) AS AverageOrderValue,
    
    -- Catégories de produits achetées
    (
        SELECT COUNT(DISTINCT p.CategoryName)
        FROM Orders o
        INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
        INNER JOIN Products p ON od.ProductID = p.ProductID
        WHERE o.ClientID = c.ClientID
    ) AS UniqueCategories,
    
    -- Catégorie préférée
    (
        SELECT TOP 1 p.CategoryName
        FROM Orders o
        INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
        INNER JOIN Products p ON od.ProductID = p.ProductID
        WHERE o.ClientID = c.ClientID
        GROUP BY p.CategoryName
        ORDER BY COUNT(*) DESC, SUM(od.Quantity) DESC
    ) AS FavoriteCategory,
    
    -- Taux de conversion (commandes / visites du site)
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM WebsiteVisits wv
            WHERE wv.ClientID = c.ClientID
        ) = 0 THEN 0
        ELSE (
            SELECT COUNT(*)
            FROM Orders o
            WHERE o.ClientID = c.ClientID
        ) * 100.0 / (
            SELECT COUNT(*)
            FROM WebsiteVisits wv
            WHERE wv.ClientID = c.ClientID
        )
    END AS ConversionRate,
    
    -- Taux d'abandon de panier
    (
        SELECT COALESCE(AVG(CASE WHEN ca.IsConverted = 'Y' THEN 0 ELSE 1 END), 0) * 100
        FROM CartAbandonment ca
        WHERE ca.ClientID = c.ClientID
    ) AS CartAbandonmentRate,
    
    -- Sensibilité aux promotions
    (
        SELECT COUNT(*)
        FROM Orders o
        WHERE o.ClientID = c.ClientID
        AND o.PromotionID IS NOT NULL
    ) * 100.0 / NULLIF(
        (
            SELECT COUNT(*)
            FROM Orders o
            WHERE o.ClientID = c.ClientID
        ), 0
    ) AS PromotionSensitivity,
    
    -- Taux de retour de produits
    CASE
        WHEN (
            SELECT SUM(od.Quantity)
            FROM Orders o
            INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
            WHERE o.ClientID = c.ClientID
        ) = 0 THEN 0
        ELSE (
            SELECT COUNT(*)
            FROM ProductReturns pr
            INNER JOIN OrderDetails od ON pr.OrderDetailID = od.OrderDetailID
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE o.ClientID = c.ClientID
        ) * 100.0 / (
            SELECT SUM(od.Quantity)
            FROM Orders o
            INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
            WHERE o.ClientID = c.ClientID
        )
    END AS ReturnRate,
    
    -- Score d'engagement (combinaison de plusieurs facteurs)
    (
        -- Récence (plus récent = meilleur score)
        CASE
            WHEN (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) <= 30 THEN 5
            WHEN (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) <= 90 THEN 4
            WHEN (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) <= 180 THEN 3
            WHEN (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) <= 365 THEN 2
            ELSE 1
        END +
        -- Fréquence (plus de commandes = meilleur score)
        CASE
            WHEN (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 10 THEN 5
            WHEN (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 5 THEN 4
            WHEN (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 3 THEN 3
            WHEN (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 1 THEN 2
            ELSE 1
        END +
        -- Valeur (plus dépensé = meilleur score)
        CASE
            WHEN (
                SELECT SUM(o.TotalAmount)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 5000 THEN 5
            WHEN (
                SELECT SUM(o.TotalAmount)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 1000 THEN 4
            WHEN (
                SELECT SUM(o.TotalAmount)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 500 THEN 3
            WHEN (
                SELECT SUM(o.TotalAmount)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 100 THEN 2
            ELSE 1
        END +
        -- Engagement sur le site (plus de visites = meilleur score)
        CASE
            WHEN (
                SELECT COUNT(*)
                FROM WebsiteVisits wv
                WHERE wv.ClientID = c.ClientID
                AND wv.VisitDate >= DATEADD(MONTH, -3, GETDATE())
            ) >= 20 THEN 5
            WHEN (
                SELECT COUNT(*)
                FROM WebsiteVisits wv
                WHERE wv.ClientID = c.ClientID
                AND wv.VisitDate >= DATEADD(MONTH, -3, GETDATE())
            ) >= 10 THEN 4
            WHEN (
                SELECT COUNT(*)
                FROM WebsiteVisits wv
                WHERE wv.ClientID = c.ClientID
                AND wv.VisitDate >= DATEADD(MONTH, -3, GETDATE())
            ) >= 5 THEN 3
            WHEN (
                SELECT COUNT(*)
                FROM WebsiteVisits wv
                WHERE wv.ClientID = c.ClientID
                AND wv.VisitDate >= DATEADD(MONTH, -3, GETDATE())
            ) >= 1 THEN 2
            ELSE 1
        END
    ) AS EngagementScore,
    
    -- Segmentation finale basée sur les scores calculés
    CASE
        -- Clients VIP
        WHEN (
            (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) <= 90
            AND (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 5
            AND (
                SELECT SUM(o.TotalAmount)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 1000
        ) THEN 'VIP'
        
        -- Clients fidèles
        WHEN (
            (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) <= 180
            AND (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 3
        ) THEN 'Fidèle'
        
        -- Clients potentiels
        WHEN (
            (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) <= 90
            AND (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) < 3
            AND (
                SELECT AVG(o.TotalAmount)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 100
        ) THEN 'Potentiel'
        
        -- Clients à risque
        WHEN (
            (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) BETWEEN 180 AND 365
            AND (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 2
        ) THEN 'À risque'
        
        -- Clients inactifs
        WHEN (
            (
                SELECT DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) > 365
        ) THEN 'Inactif'
        
        -- Nouveaux clients
        WHEN (
            DATEDIFF(DAY, c.RegistrationDate, GETDATE()) <= 90
            AND (
                SELECT COUNT(*)
                FROM Orders o
                WHERE o.ClientID = c.ClientID
            ) >= 1
        ) THEN 'Nouveau'
        
        -- Clients occasionnels
        ELSE 'Occasionnel'
    END AS CustomerSegment
FROM
    Customers c
WHERE
    c.IsActive = 'Y'
ORDER BY
    EngagementScore DESC; 