-- Requête avec sous-requêtes complexes 1: Prévisions de ventes
-- Description: Cette requête utilise des sous-requêtes complexes pour générer
-- des prévisions de ventes basées sur les tendances historiques

SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    
    -- Ventes des 12 derniers mois
    (
        SELECT SUM(od.Quantity)
        FROM OrderDetails od
        INNER JOIN Orders o ON od.OrderID = o.OrderID
        WHERE od.ProductID = p.ProductID
        AND o.OrderDate BETWEEN DATEADD(YEAR, -1, GETDATE()) AND GETDATE()
    ) AS SalesLast12Months,
    
    -- Ventes par trimestre
    (
        SELECT SUM(od.Quantity)
        FROM OrderDetails od
        INNER JOIN Orders o ON od.OrderID = o.OrderID
        WHERE od.ProductID = p.ProductID
        AND o.OrderDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()
    ) AS SalesLastQuarter,
    
    (
        SELECT SUM(od.Quantity)
        FROM OrderDetails od
        INNER JOIN Orders o ON od.OrderID = o.OrderID
        WHERE od.ProductID = p.ProductID
        AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
    ) AS SalesPreviousQuarter,
    
    -- Calcul de la croissance trimestrielle
    CASE
        WHEN (
            SELECT SUM(od.Quantity)
            FROM OrderDetails od
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID
            AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
        ) = 0 THEN NULL
        ELSE (
            (
                SELECT SUM(od.Quantity)
                FROM OrderDetails od
                INNER JOIN Orders o ON od.OrderID = o.OrderID
                WHERE od.ProductID = p.ProductID
                AND o.OrderDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()
            ) - 
            (
                SELECT SUM(od.Quantity)
                FROM OrderDetails od
                INNER JOIN Orders o ON od.OrderID = o.OrderID
                WHERE od.ProductID = p.ProductID
                AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
            )
        ) / (
            SELECT SUM(od.Quantity)
            FROM OrderDetails od
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID
            AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
        ) * 100
    END AS QuarterlyGrowthRate,
    
    -- Saisonnalité (comparaison avec la même période l'année précédente)
    CASE
        WHEN (
            SELECT SUM(od.Quantity)
            FROM OrderDetails od
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID
            AND o.OrderDate BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH, -3, GETDATE())) AND DATEADD(YEAR, -1, GETDATE())
        ) = 0 THEN NULL
        ELSE (
            (
                SELECT SUM(od.Quantity)
                FROM OrderDetails od
                INNER JOIN Orders o ON od.OrderID = o.OrderID
                WHERE od.ProductID = p.ProductID
                AND o.OrderDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()
            ) - 
            (
                SELECT SUM(od.Quantity)
                FROM OrderDetails od
                INNER JOIN Orders o ON od.OrderID = o.OrderID
                WHERE od.ProductID = p.ProductID
                AND o.OrderDate BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH, -3, GETDATE())) AND DATEADD(YEAR, -1, GETDATE())
            )
        ) / (
            SELECT SUM(od.Quantity)
            FROM OrderDetails od
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID
            AND o.OrderDate BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH, -3, GETDATE())) AND DATEADD(YEAR, -1, GETDATE())
        ) * 100
    END AS YearOverYearGrowthRate,
    
    -- Prévision pour le prochain trimestre basée sur la croissance et la saisonnalité
    CASE
        -- Si le produit est nouveau (moins d'un an), utiliser la croissance trimestrielle
        WHEN (
            SELECT MIN(o.OrderDate)
            FROM OrderDetails od
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID
        ) > DATEADD(YEAR, -1, GETDATE()) THEN
            (
                SELECT SUM(od.Quantity)
                FROM OrderDetails od
                INNER JOIN Orders o ON od.OrderID = o.OrderID
                WHERE od.ProductID = p.ProductID
                AND o.OrderDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()
            ) * 
            (1 + 
                CASE
                    WHEN (
                        SELECT SUM(od.Quantity)
                        FROM OrderDetails od
                        INNER JOIN Orders o ON od.OrderID = o.OrderID
                        WHERE od.ProductID = p.ProductID
                        AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
                    ) = 0 THEN 0.1 -- Croissance par défaut pour les nouveaux produits
                    ELSE (
                        (
                            SELECT SUM(od.Quantity)
                            FROM OrderDetails od
                            INNER JOIN Orders o ON od.OrderID = o.OrderID
                            WHERE od.ProductID = p.ProductID
                            AND o.OrderDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()
                        ) - 
                        (
                            SELECT SUM(od.Quantity)
                            FROM OrderDetails od
                            INNER JOIN Orders o ON od.OrderID = o.OrderID
                            WHERE od.ProductID = p.ProductID
                            AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
                        )
                    ) / (
                        SELECT SUM(od.Quantity)
                        FROM OrderDetails od
                        INNER JOIN Orders o ON od.OrderID = o.OrderID
                        WHERE od.ProductID = p.ProductID
                        AND o.OrderDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE())
                    )
                END
            )
        -- Sinon, utiliser la saisonnalité et la tendance
        ELSE
            (
                SELECT SUM(od.Quantity)
                FROM OrderDetails od
                INNER JOIN Orders o ON od.OrderID = o.OrderID
                WHERE od.ProductID = p.ProductID
                AND o.OrderDate BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH, 3, GETDATE())) AND DATEADD(YEAR, -1, DATEADD(MONTH, 6, GETDATE()))
            ) * 
            (1 + 
                CASE
                    WHEN (
                        SELECT AVG(
                            CASE
                                WHEN PrevYearQuarter = 0 THEN NULL
                                ELSE (CurrentQuarter - PrevYearQuarter) / PrevYearQuarter
                            END
                        )
                        FROM (
                            SELECT
                                DATEPART(QUARTER, o.OrderDate) AS QuarterNum,
                                YEAR(o.OrderDate) AS YearNum,
                                SUM(od.Quantity) AS CurrentQuarter,
                                (
                                    SELECT SUM(od2.Quantity)
                                    FROM OrderDetails od2
                                    INNER JOIN Orders o2 ON od2.OrderID = o2.OrderID
                                    WHERE od2.ProductID = p.ProductID
                                    AND DATEPART(QUARTER, o2.OrderDate) = DATEPART(QUARTER, o.OrderDate)
                                    AND YEAR(o2.OrderDate) = YEAR(o.OrderDate) - 1
                                ) AS PrevYearQuarter
                            FROM
                                OrderDetails od
                            INNER JOIN
                                Orders o ON od.OrderID = o.OrderID
                            WHERE
                                od.ProductID = p.ProductID
                                AND o.OrderDate >= DATEADD(YEAR, -2, GETDATE())
                            GROUP BY
                                DATEPART(QUARTER, o.OrderDate),
                                YEAR(o.OrderDate)
                        ) AS QuarterlyGrowth
                    ) IS NULL THEN 0.05 -- Croissance par défaut
                    ELSE (
                        SELECT AVG(
                            CASE
                                WHEN PrevYearQuarter = 0 THEN NULL
                                ELSE (CurrentQuarter - PrevYearQuarter) / PrevYearQuarter
                            END
                        )
                        FROM (
                            SELECT
                                DATEPART(QUARTER, o.OrderDate) AS QuarterNum,
                                YEAR(o.OrderDate) AS YearNum,
                                SUM(od.Quantity) AS CurrentQuarter,
                                (
                                    SELECT SUM(od2.Quantity)
                                    FROM OrderDetails od2
                                    INNER JOIN Orders o2 ON od2.OrderID = o2.OrderID
                                    WHERE od2.ProductID = p.ProductID
                                    AND DATEPART(QUARTER, o2.OrderDate) = DATEPART(QUARTER, o.OrderDate)
                                    AND YEAR(o2.OrderDate) = YEAR(o.OrderDate) - 1
                                ) AS PrevYearQuarter
                            FROM
                                OrderDetails od
                            INNER JOIN
                                Orders o ON od.OrderID = o.OrderID
                            WHERE
                                od.ProductID = p.ProductID
                                AND o.OrderDate >= DATEADD(YEAR, -2, GETDATE())
                            GROUP BY
                                DATEPART(QUARTER, o.OrderDate),
                                YEAR(o.OrderDate)
                        ) AS QuarterlyGrowth
                    )
                END
            )
    END AS NextQuarterForecast,
    
    -- Facteurs influençant les prévisions
    (
        SELECT STRING_AGG(PromotionName, ', ')
        FROM ProductPromotions
        WHERE ProductID = p.ProductID
        AND StartDate BETWEEN GETDATE() AND DATEADD(MONTH, 3, GETDATE())
    ) AS UpcomingPromotions,
    
    -- Indice de confiance de la prévision
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM OrderDetails od
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID
        ) < 10 THEN 'Faible'
        WHEN (
            SELECT STDEV(MonthlyQuantity)
            FROM (
                SELECT
                    YEAR(o.OrderDate) * 100 + MONTH(o.OrderDate) AS YearMonth,
                    SUM(od.Quantity) AS MonthlyQuantity
                FROM
                    OrderDetails od
                INNER JOIN
                    Orders o ON od.OrderID = o.OrderID
                WHERE
                    od.ProductID = p.ProductID
                    AND o.OrderDate >= DATEADD(YEAR, -2, GETDATE())
                GROUP BY
                    YEAR(o.OrderDate) * 100 + MONTH(o.OrderDate)
            ) AS MonthlySales
        ) / (
            SELECT AVG(MonthlyQuantity)
            FROM (
                SELECT
                    YEAR(o.OrderDate) * 100 + MONTH(o.OrderDate) AS YearMonth,
                    SUM(od.Quantity) AS MonthlyQuantity
                FROM
                    OrderDetails od
                INNER JOIN
                    Orders o ON od.OrderID = o.OrderID
                WHERE
                    od.ProductID = p.ProductID
                    AND o.OrderDate >= DATEADD(YEAR, -2, GETDATE())
                GROUP BY
                    YEAR(o.OrderDate) * 100 + MONTH(o.OrderDate)
            ) AS MonthlySales
        ) > 0.5 THEN 'Moyen'
        ELSE 'Élevé'
    END AS ForecastConfidence
FROM
    Products p
WHERE
    p.IsDiscontinued = 'N'
    AND (
        SELECT SUM(od.Quantity)
        FROM OrderDetails od
        INNER JOIN Orders o ON od.OrderID = o.OrderID
        WHERE od.ProductID = p.ProductID
        AND o.OrderDate BETWEEN DATEADD(YEAR, -1, GETDATE()) AND GETDATE()
    ) > 0
ORDER BY
    SalesLast12Months DESC; 