-- Requête avec sous-requêtes complexes : Sous-requêtes dans la clause SELECT
-- Cette requête analyse les performances des produits avec diverses métriques calculées

SELECT 
    P.ProductID,
    P.ProductName,
    C.CategoryName,
    P.UnitPrice,
    P.UnitsInStock,
    
    -- Sous-requête 1 : Total des ventes pour ce produit
    (
        SELECT SUM(OD.Quantity)
        FROM OrderDetails OD
        JOIN Orders O ON OD.OrderID = O.OrderID
        WHERE OD.ProductID = P.ProductID
        AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    ) AS TotalQuantitySold,
    
    -- Sous-requête 2 : Chiffre d'affaires total pour ce produit
    (
        SELECT SUM(OD.Quantity * OD.UnitPrice)
        FROM OrderDetails OD
        JOIN Orders O ON OD.OrderID = O.OrderID
        WHERE OD.ProductID = P.ProductID
        AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    ) AS TotalRevenue,
    
    -- Sous-requête 3 : Nombre de commandes distinctes contenant ce produit
    (
        SELECT COUNT(DISTINCT O.OrderID)
        FROM Orders O
        JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        WHERE OD.ProductID = P.ProductID
        AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    ) AS OrderCount,
    
    -- Sous-requête 4 : Nombre de clients distincts ayant acheté ce produit
    (
        SELECT COUNT(DISTINCT O.CustomerID)
        FROM Orders O
        JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        WHERE OD.ProductID = P.ProductID
        AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    ) AS CustomerCount,
    
    -- Sous-requête 5 : Date de la dernière commande de ce produit
    (
        SELECT MAX(O.OrderDate)
        FROM Orders O
        JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        WHERE OD.ProductID = P.ProductID
    ) AS LastOrderDate,
    
    -- Sous-requête 6 : Moyenne des quantités commandées par commande
    (
        SELECT AVG(OD.Quantity)
        FROM OrderDetails OD
        JOIN Orders O ON OD.OrderID = O.OrderID
        WHERE OD.ProductID = P.ProductID
        AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    ) AS AvgQuantityPerOrder,
    
    -- Sous-requête 7 : Classement du produit par chiffre d'affaires dans sa catégorie
    (
        SELECT COUNT(*) + 1
        FROM (
            SELECT 
                SubP.ProductID,
                SUM(SubOD.Quantity * SubOD.UnitPrice) AS Revenue
            FROM 
                Products SubP
                JOIN OrderDetails SubOD ON SubP.ProductID = SubOD.ProductID
                JOIN Orders SubO ON SubOD.OrderID = SubO.OrderID
            WHERE 
                SubP.CategoryID = P.CategoryID
                AND SubO.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            GROUP BY 
                SubP.ProductID
        ) RankedProducts
        WHERE 
            RankedProducts.Revenue > (
                SELECT SUM(OD.Quantity * OD.UnitPrice)
                FROM OrderDetails OD
                JOIN Orders O ON OD.OrderID = O.OrderID
                WHERE OD.ProductID = P.ProductID
                AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
            )
    ) AS CategoryRank,
    
    -- Sous-requête 8 : Pourcentage des ventes totales de la catégorie
    (
        SELECT 
            (SUM(OD.Quantity * OD.UnitPrice) / 
                NULLIF((
                    SELECT SUM(SubOD.Quantity * SubOD.UnitPrice)
                    FROM OrderDetails SubOD
                    JOIN Orders SubO ON SubOD.OrderID = SubO.OrderID
                    JOIN Products SubP ON SubOD.ProductID = SubP.ProductID
                    WHERE SubP.CategoryID = P.CategoryID
                    AND SubO.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
                ), 0)
            ) * 100
        FROM OrderDetails OD
        JOIN Orders O ON OD.OrderID = O.OrderID
        WHERE OD.ProductID = P.ProductID
        AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    ) AS PercentOfCategorySales,
    
    -- Sous-requête 9 : Taux de rotation du stock
    CASE 
        WHEN P.UnitsInStock = 0 THEN NULL
        ELSE (
            SELECT CAST(SUM(OD.Quantity) AS FLOAT) / CAST(P.UnitsInStock AS FLOAT)
            FROM OrderDetails OD
            JOIN Orders O ON OD.OrderID = O.OrderID
            WHERE OD.ProductID = P.ProductID
            AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
        )
    END AS StockTurnoverRate,
    
    -- Sous-requête 10 : Prévision des ventes pour le mois prochain basée sur la tendance
    (
        SELECT 
            AVG(MonthlyQuantity) + 
            (
                (MAX(CASE WHEN MonthRank = 1 THEN MonthlyQuantity ELSE 0 END) - 
                 MAX(CASE WHEN MonthRank = 3 THEN MonthlyQuantity ELSE 0 END)) / 2
            )
        FROM (
            SELECT 
                SUM(OD.Quantity) AS MonthlyQuantity,
                DENSE_RANK() OVER (ORDER BY YEAR(O.OrderDate) DESC, MONTH(O.OrderDate) DESC) AS MonthRank
            FROM 
                OrderDetails OD
                JOIN Orders O ON OD.OrderID = O.OrderID
            WHERE 
                OD.ProductID = P.ProductID
                AND O.OrderDate >= DATEADD(MONTH, -6, GETDATE())
            GROUP BY 
                YEAR(O.OrderDate),
                MONTH(O.OrderDate)
        ) AS MonthlySales
        WHERE MonthRank <= 3
    ) AS NextMonthForecast
FROM 
    Products P
    JOIN Categories C ON P.CategoryID = C.CategoryID
WHERE 
    P.Discontinued = 0
    AND (
        SELECT COUNT(*)
        FROM OrderDetails OD
        JOIN Orders O ON OD.OrderID = O.OrderID
        WHERE OD.ProductID = P.ProductID
        AND O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    ) > 0
ORDER BY 
    C.CategoryName,
    TotalRevenue DESC; 