-- Requête complexe : Transaction avec gestion d'erreurs
-- Cette requête effectue une série d'opérations dans une transaction avec gestion d'erreurs

BEGIN TRY
    -- Démarrer la transaction
    BEGIN TRANSACTION;
    
    DECLARE @OrderID INT;
    DECLARE @CustomerID INT = 1001;
    DECLARE @OrderDate DATETIME = GETDATE();
    DECLARE @TotalAmount DECIMAL(10, 2) = 0;
    
    -- Vérifier si le client existe
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID = @CustomerID)
    BEGIN
        THROW 50001, 'Le client spécifié n''existe pas.', 1;
    END
    
    -- Insérer la commande
    INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
    VALUES (@CustomerID, @OrderDate, @TotalAmount, 'En attente');
    
    -- Récupérer l'ID de la commande insérée
    SET @OrderID = SCOPE_IDENTITY();
    
    -- Déclarer une table temporaire pour les produits à commander
    DECLARE @OrderProducts TABLE (
        ProductID INT,
        Quantity INT,
        UnitPrice DECIMAL(10, 2)
    );
    
    -- Insérer les produits à commander dans la table temporaire
    INSERT INTO @OrderProducts (ProductID, Quantity, UnitPrice)
    VALUES 
        (101, 5, 25.99),
        (203, 2, 49.95),
        (305, 1, 199.99);
    
    -- Vérifier la disponibilité des produits
    IF EXISTS (
        SELECT 1 
        FROM @OrderProducts op
        JOIN Products p ON op.ProductID = p.ProductID
        WHERE p.UnitsInStock < op.Quantity
    )
    BEGIN
        THROW 50002, 'Un ou plusieurs produits ne sont pas disponibles en quantité suffisante.', 1;
    END
    
    -- Insérer les détails de la commande
    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
    SELECT 
        @OrderID,
        ProductID,
        Quantity,
        UnitPrice
    FROM 
        @OrderProducts;
    
    -- Mettre à jour le stock des produits
    UPDATE p
    SET p.UnitsInStock = p.UnitsInStock - op.Quantity
    FROM Products p
    JOIN @OrderProducts op ON p.ProductID = op.ProductID;
    
    -- Calculer le montant total de la commande
    SELECT @TotalAmount = SUM(Quantity * UnitPrice)
    FROM @OrderProducts;
    
    -- Mettre à jour le montant total de la commande
    UPDATE Orders
    SET TotalAmount = @TotalAmount
    WHERE OrderID = @OrderID;
    
    -- Enregistrer les modifications dans le journal d'audit
    INSERT INTO AuditLog (TableName, RecordID, Action, ActionDate, UserID)
    VALUES ('Orders', @OrderID, 'INSERT', GETDATE(), SYSTEM_USER);
    
    -- Valider la transaction
    COMMIT TRANSACTION;
    
    -- Retourner les informations de la commande
    SELECT 
        o.OrderID,
        o.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        o.OrderDate,
        o.TotalAmount,
        o.Status
    FROM 
        Orders o
        JOIN Customers c ON o.CustomerID = c.CustomerID
    WHERE 
        o.OrderID = @OrderID;
    
END TRY
BEGIN CATCH
    -- En cas d'erreur, annuler la transaction
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    -- Enregistrer l'erreur dans le journal
    INSERT INTO ErrorLog (ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine, ErrorMessage, ErrorDate)
    VALUES (
        ERROR_NUMBER(),
        ERROR_SEVERITY(),
        ERROR_STATE(),
        ERROR_PROCEDURE(),
        ERROR_LINE(),
        ERROR_MESSAGE(),
        GETDATE()
    );
    
    -- Renvoyer les informations d'erreur
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH; 