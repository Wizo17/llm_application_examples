-- Requête avec sous-requêtes complexes 3: Analyse du panier d'achat
-- Description: Cette requête utilise des sous-requêtes imbriquées pour analyser
-- les associations entre produits et identifier les opportunités de ventes croisées

WITH ProductPairs AS (
    -- Identification des paires de produits achetés ensemble
    SELECT
        od1.ProductID AS Product1ID,
        p1.ProductName AS Product1Name,
        p1.CategoryName AS Product1Category,
        od2.ProductID AS Product2ID,
        p2.ProductName AS Product2Name,
        p2.CategoryName AS Product2Category,
        COUNT(DISTINCT od1.OrderID) AS TimesOrdered
    FROM
        OrderDetails od1
    INNER JOIN
        OrderDetails od2 ON od1.OrderID = od2.OrderID AND od1.ProductID < od2.ProductID
    INNER JOIN
        Products p1 ON od1.ProductID = p1.ProductID
    INNER JOIN
        Products p2 ON od2.ProductID = p2.ProductID
    INNER JOIN
        Orders o ON od1.OrderID = o.OrderID
    WHERE
        o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY
        od1.ProductID,
        p1.ProductName,
        p1.CategoryName,
        od2.ProductID,
        p2.ProductName,
        p2.CategoryName
    HAVING
        COUNT(DISTINCT od1.OrderID) >= 5
),
ProductFrequency AS (
    -- Calcul de la fréquence d'achat de chaque produit
    SELECT
        p.ProductID,
        p.ProductName,
        COUNT(DISTINCT o.OrderID) AS OrderCount
    FROM
        Products p
    INNER JOIN
        OrderDetails od ON p.ProductID = od.ProductID
    INNER JOIN
        Orders o ON od.OrderID = o.OrderID
    WHERE
        o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY
        p.ProductID,
        p.ProductName
),
TotalOrders AS (
    -- Nombre total de commandes sur la période
    SELECT
        COUNT(DISTINCT OrderID) AS OrderCount
    FROM
        Orders
    WHERE
        OrderDate >= DATEADD(YEAR, -1, GETDATE())
),
MarketBasketMetrics AS (
    -- Calcul des métriques d'association pour chaque paire de produits
    SELECT
        pp.Product1ID,
        pp.Product1Name,
        pp.Product1Category,
        pp.Product2ID,
        pp.Product2Name,
        pp.Product2Category,
        pp.TimesOrdered,
        pf1.OrderCount AS Product1Frequency,
        pf2.OrderCount AS Product2Frequency,
        to1.OrderCount AS TotalOrders,
        -- Support (probabilité que les deux produits soient achetés ensemble)
        CAST(pp.TimesOrdered AS FLOAT) / to1.OrderCount AS Support,
        -- Confiance (probabilité d'acheter le produit 2 sachant qu'on a acheté le produit 1)
        CAST(pp.TimesOrdered AS FLOAT) / pf1.OrderCount AS Confidence1to2,
        -- Confiance (probabilité d'acheter le produit 1 sachant qu'on a acheté le produit 2)
        CAST(pp.TimesOrdered AS FLOAT) / pf2.OrderCount AS Confidence2to1,
        -- Lift (mesure de l'indépendance des produits)
        (CAST(pp.TimesOrdered AS FLOAT) * to1.OrderCount) / (pf1.OrderCount * pf2.OrderCount) AS Lift,
        -- Conviction (mesure de l'implication)
        CASE
            WHEN CAST(pp.TimesOrdered AS FLOAT) / pf1.OrderCount = 1 THEN 999999.0
            ELSE (1 - (CAST(pf2.OrderCount AS FLOAT) / to1.OrderCount)) / (1 - (CAST(pp.TimesOrdered AS FLOAT) / pf1.OrderCount))
        END AS Conviction1to2,
        CASE
            WHEN CAST(pp.TimesOrdered AS FLOAT) / pf2.OrderCount = 1 THEN 999999.0
            ELSE (1 - (CAST(pf1.OrderCount AS FLOAT) / to1.OrderCount)) / (1 - (CAST(pp.TimesOrdered AS FLOAT) / pf2.OrderCount))
        END AS Conviction2to1
    FROM
        ProductPairs pp
    INNER JOIN
        ProductFrequency pf1 ON pp.Product1ID = pf1.ProductID
    INNER JOIN
        ProductFrequency pf2 ON pp.Product2ID = pf2.ProductID
    CROSS JOIN
        TotalOrders to1
)
SELECT
    mbm.Product1ID,
    mbm.Product1Name,
    mbm.Product1Category,
    mbm.Product2ID,
    mbm.Product2Name,
    mbm.Product2Category,
    mbm.TimesOrdered,
    mbm.Product1Frequency,
    mbm.Product2Frequency,
    mbm.Support,
    mbm.Confidence1to2,
    mbm.Confidence2to1,
    mbm.Lift,
    mbm.Conviction1to2,
    mbm.Conviction2to1,
    
    -- Classement des paires par lift
    RANK() OVER (ORDER BY mbm.Lift DESC) AS LiftRank,
    
    -- Classement des paires par support
    RANK() OVER (ORDER BY mbm.Support DESC) AS SupportRank,
    
    -- Classement des paires par confiance
    RANK() OVER (ORDER BY mbm.Confidence1to2 DESC) AS Confidence1to2Rank,
    RANK() OVER (ORDER BY mbm.Confidence2to1 DESC) AS Confidence2to1Rank,
    
    -- Recommandation basée sur les métriques
    CASE
        WHEN mbm.Lift > 3 AND mbm.Support > 0.01 AND mbm.Confidence1to2 > 0.5 THEN 'Forte recommandation'
        WHEN mbm.Lift > 2 AND mbm.Support > 0.005 AND mbm.Confidence1to2 > 0.3 THEN 'Recommandation moyenne'
        WHEN mbm.Lift > 1.5 THEN 'Recommandation faible'
        ELSE 'Pas de recommandation'
    END AS RecommendationStrength,
    
    -- Vérification si les produits sont déjà vendus ensemble dans des bundles
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM ProductBundles pb
            INNER JOIN BundleItems bi1 ON pb.BundleID = bi1.BundleID
            INNER JOIN BundleItems bi2 ON pb.BundleID = bi2.BundleID
            WHERE bi1.ProductID = mbm.Product1ID AND bi2.ProductID = mbm.Product2ID
        ) THEN 'Déjà en bundle'
        ELSE 'Pas en bundle'
    END AS BundleStatus,
    
    -- Vérification des promotions croisées existantes
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM CrossSellPromotions csp
            WHERE (csp.TriggerProductID = mbm.Product1ID AND csp.OfferedProductID = mbm.Product2ID)
               OR (csp.TriggerProductID = mbm.Product2ID AND csp.OfferedProductID = mbm.Product1ID)
        ) THEN 'Promotion croisée existante'
        ELSE 'Pas de promotion croisée'
    END AS CrossSellStatus,
    
    -- Calcul de la marge combinée
    (
        SELECT p1.ProfitMargin
        FROM Products p1
        WHERE p1.ProductID = mbm.Product1ID
    ) + (
        SELECT p2.ProfitMargin
        FROM Products p2
        WHERE p2.ProductID = mbm.Product2ID
    ) AS CombinedMargin,
    
    -- Suggestion de prix pour un bundle
    CASE
        WHEN mbm.Lift > 2 THEN
            ROUND(
                ((
                    SELECT p1.ListPrice
                    FROM Products p1
                    WHERE p1.ProductID = mbm.Product1ID
                ) + (
                    SELECT p2.ListPrice
                    FROM Products p2
                    WHERE p2.ProductID = mbm.Product2ID
                )) * 0.9, 2
            )
        ELSE
            ROUND(
                ((
                    SELECT p1.ListPrice
                    FROM Products p1
                    WHERE p1.ProductID = mbm.Product1ID
                ) + (
                    SELECT p2.ListPrice
                    FROM Products p2
                    WHERE p2.ProductID = mbm.Product2ID
                )) * 0.95, 2
            )
    END AS SuggestedBundlePrice,
    
    -- Tendance récente (augmentation ou diminution des achats combinés)
    CASE
        WHEN (
            SELECT COUNT(DISTINCT o.OrderID)
            FROM OrderDetails od1
            INNER JOIN OrderDetails od2 ON od1.OrderID = od2.OrderID
            INNER JOIN Orders o ON od1.OrderID = o.OrderID
            WHERE od1.ProductID = mbm.Product1ID
            AND od2.ProductID = mbm.Product2ID
            AND o.OrderDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()
        ) > (
            SELECT COUNT(DISTINCT o.OrderID)
            FROM OrderDetails od1
            INNER JOIN OrderDetails od2 ON od1.OrderID = od2.OrderID
            INNER JOIN Orders o ON od1.OrderID = o.OrderID
            WHERE od1.ProductID = mbm.Product1ID
            AND od2.ProductID = mbm.Product2ID
            AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
        ) THEN 'En hausse'
        WHEN (
            SELECT COUNT(DISTINCT o.OrderID)
            FROM OrderDetails od1
            INNER JOIN OrderDetails od2 ON od1.OrderID = od2.OrderID
            INNER JOIN Orders o ON od1.OrderID = o.OrderID
            WHERE od1.ProductID = mbm.Product1ID
            AND od2.ProductID = mbm.Product2ID
            AND o.OrderDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()
        ) < (
            SELECT COUNT(DISTINCT o.OrderID)
            FROM OrderDetails od1
            INNER JOIN OrderDetails od2 ON od1.OrderID = od2.OrderID
            INNER JOIN Orders o ON od1.OrderID = o.OrderID
            WHERE od1.ProductID = mbm.Product1ID
            AND od2.ProductID = mbm.Product2ID
            AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
        ) THEN 'En baisse'
        ELSE 'Stable'
    END AS RecentTrend
FROM
    MarketBasketMetrics mbm
WHERE
    mbm.Lift > 1.2  -- Filtre sur les associations significatives
ORDER BY
    mbm.Lift DESC,
    mbm.Support DESC; 