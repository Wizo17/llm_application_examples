-- Requête complexe 1: Segmentation des clients avec CTE
-- Description: Cette requête utilise des Common Table Expressions pour segmenter
-- les clients selon leur valeur (RFM - Récence, Fréquence, Montant)

WITH CustomerRecency AS (
    SELECT
        c.ClientID,
        c.FirstName,
        c.LastName,
        MAX(o.OrderDate) AS LastOrderDate,
        DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS DaysSinceLastOrder,
        NTILE(4) OVER (ORDER BY DATEDIFF(DAY, MAX(o.OrderDate), GETDATE())) AS RecencyScore
    FROM
        Customers c
    INNER JOIN
        Orders o ON c.ClientID = o.ClientID
    GROUP BY
        c.ClientID, c.FirstName, c.LastName
),
CustomerFrequency AS (
    SELECT
        c.ClientID,
        COUNT(o.OrderID) AS OrderCount,
        NTILE(4) OVER (ORDER BY COUNT(o.OrderID)) AS FrequencyScore
    FROM
        Customers c
    INNER JOIN
        Orders o ON c.ClientID = o.ClientID
    WHERE
        o.OrderDate >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY
        c.ClientID
),
CustomerMonetary AS (
    SELECT
        c.ClientID,
        SUM(o.TotalAmount) AS TotalSpent,
        NTILE(4) OVER (ORDER BY SUM(o.TotalAmount)) AS MonetaryScore
    FROM
        Customers c
    INNER JOIN
        Orders o ON c.ClientID = o.ClientID
    WHERE
        o.OrderDate >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY
        c.ClientID
),
CustomerRFM AS (
    SELECT
        r.ClientID,
        r.FirstName,
        r.LastName,
        r.LastOrderDate,
        r.DaysSinceLastOrder,
        r.RecencyScore,
        f.OrderCount,
        f.FrequencyScore,
        m.TotalSpent,
        m.MonetaryScore,
        CONCAT(r.RecencyScore, f.FrequencyScore, m.MonetaryScore) AS RFMScore
    FROM
        CustomerRecency r
    INNER JOIN
        CustomerFrequency f ON r.ClientID = f.ClientID
    INNER JOIN
        CustomerMonetary m ON r.ClientID = m.ClientID
)
SELECT
    ClientID,
    FirstName,
    LastName,
    LastOrderDate,
    DaysSinceLastOrder,
    OrderCount,
    TotalSpent,
    RFMScore,
    CASE
        WHEN RFMScore IN ('444', '443', '434', '344', '433', '343', '334') THEN 'Champions'
        WHEN RFMScore IN ('442', '432', '342', '332', '423', '324', '333') THEN 'Loyal Customers'
        WHEN RFMScore IN ('441', '431', '341', '331', '422', '322', '323', '332') THEN 'Potential Loyalists'
        WHEN RFMScore IN ('424', '414', '413', '314', '234', '243', '242', '241') THEN 'New Customers'
        WHEN RFMScore IN ('411', '311', '221', '212', '211', '121', '112', '111') THEN 'At Risk'
        WHEN RFMScore IN ('144', '134', '143', '133', '124', '123', '122', '142') THEN 'Cannot Lose Them'
        WHEN RFMScore IN ('141', '131', '132', '231', '222', '223', '232', '233') THEN 'Hibernating'
        WHEN RFMScore IN ('114', '113', '214', '213') THEN 'About to Sleep'
        ELSE 'Others'
    END AS CustomerSegment
FROM
    CustomerRFM
ORDER BY
    CASE
        WHEN RFMScore IN ('444', '443', '434', '344', '433', '343', '334') THEN 1
        WHEN RFMScore IN ('442', '432', '342', '332', '423', '324', '333') THEN 2
        WHEN RFMScore IN ('441', '431', '341', '331', '422', '322', '323', '332') THEN 3
        WHEN RFMScore IN ('424', '414', '413', '314', '234', '243', '242', '241') THEN 4
        WHEN RFMScore IN ('411', '311', '221', '212', '211', '121', '112', '111') THEN 5
        WHEN RFMScore IN ('144', '134', '143', '133', '124', '123', '122', '142') THEN 6
        WHEN RFMScore IN ('141', '131', '132', '231', '222', '223', '232', '233') THEN 7
        WHEN RFMScore IN ('114', '113', '214', '213') THEN 8
        ELSE 9
    END,
    TotalSpent DESC; 