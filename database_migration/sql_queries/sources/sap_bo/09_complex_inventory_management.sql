-- Requête complexe 3: Gestion des stocks avec transactions
-- Description: Cette requête utilise des transactions pour mettre à jour les niveaux de stock
-- et générer des alertes de réapprovisionnement

BEGIN TRANSACTION;

-- Mise à jour temporaire des niveaux de stock basée sur les commandes récentes
WITH StockUpdates AS (
    SELECT
        p.ProductID,
        p.ProductName,
        p.CurrentStock,
        p.ReorderLevel,
        p.SafetyStock,
        SUM(od.Quantity) AS TotalOrdered,
        p.CurrentStock - SUM(od.Quantity) AS ProjectedStock,
        CASE
            WHEN (p.CurrentStock - SUM(od.Quantity)) <= p.ReorderLevel THEN 'Réapprovisionnement nécessaire'
            WHEN (p.CurrentStock - SUM(od.Quantity)) <= p.SafetyStock THEN 'Stock de sécurité atteint'
            ELSE 'Stock suffisant'
        END AS StockStatus
    FROM
        Products p
    INNER JOIN
        OrderDetails od ON p.ProductID = od.ProductID
    INNER JOIN
        Orders o ON od.OrderID = o.OrderID
    WHERE
        o.OrderStatus = 'En attente'
        AND o.OrderDate >= DATEADD(DAY, -7, GETDATE())
    GROUP BY
        p.ProductID,
        p.ProductName,
        p.CurrentStock,
        p.ReorderLevel,
        p.SafetyStock
)

-- Insertion des alertes de réapprovisionnement dans la table de suivi
INSERT INTO StockAlerts (
    ProductID,
    AlertDate,
    CurrentStock,
    ProjectedStock,
    AlertType,
    IsProcessed
)
SELECT
    ProductID,
    GETDATE() AS AlertDate,
    CurrentStock,
    ProjectedStock,
    StockStatus AS AlertType,
    0 AS IsProcessed
FROM
    StockUpdates
WHERE
    StockStatus IN ('Réapprovisionnement nécessaire', 'Stock de sécurité atteint');

-- Mise à jour des niveaux de stock pour les commandes expédiées
UPDATE p
SET
    p.CurrentStock = p.CurrentStock - od.Quantity,
    p.LastUpdateDate = GETDATE()
FROM
    Products p
INNER JOIN
    OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN
    Orders o ON od.OrderID = o.OrderID
WHERE
    o.OrderStatus = 'Expédié'
    AND o.ShippingDate = CAST(GETDATE() AS DATE)
    AND p.CurrentStock >= od.Quantity;

-- Génération d'un rapport de stock pour les produits à réapprovisionner
SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    p.CurrentStock,
    p.ReorderLevel,
    p.SafetyStock,
    p.LeadTimeDays,
    s.SupplierName,
    s.ContactName,
    s.ContactEmail,
    s.ContactPhone,
    CASE
        WHEN p.CurrentStock <= p.SafetyStock THEN 'Urgent'
        WHEN p.CurrentStock <= p.ReorderLevel THEN 'Normal'
        ELSE 'Planifié'
    END AS PriorityLevel,
    (p.MaxStock - p.CurrentStock) AS QuantityToOrder,
    DATEADD(DAY, p.LeadTimeDays, GETDATE()) AS EstimatedArrivalDate
FROM
    Products p
INNER JOIN
    Suppliers s ON p.PrimarySupplierID = s.SupplierID
WHERE
    p.CurrentStock <= p.ReorderLevel
ORDER BY
    CASE
        WHEN p.CurrentStock <= p.SafetyStock THEN 1
        WHEN p.CurrentStock <= p.ReorderLevel THEN 2
        ELSE 3
    END,
    p.CategoryName,
    p.ProductName;

-- Vérification des erreurs et validation ou annulation de la transaction
IF @@ERROR = 0
BEGIN
    COMMIT TRANSACTION;
    SELECT 'Transaction réussie: Mise à jour des stocks et génération des alertes terminées.' AS ResultMessage;
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    SELECT 'Transaction annulée: Une erreur est survenue lors de la mise à jour des stocks.' AS ResultMessage;
END 