-- Requête avec jointures complexes : Jointures auto-référencées
-- Cette requête analyse la structure hiérarchique des catégories de produits et leurs performances

WITH CategoriesHierarchie AS (
    -- Catégories de niveau supérieur (sans parent)
    SELECT 
        CategoryID,
        CategoryName,
        ParentCategoryID,
        0 AS Level,
        CAST(CategoryName AS VARCHAR(255)) AS CategoryPath,
        CAST(CAST(CategoryID AS VARCHAR(10)) AS VARCHAR(255)) AS CategoryIDPath
    FROM 
        Categories
    WHERE 
        ParentCategoryID IS NULL
    
    UNION ALL
    
    -- Catégories enfants
    SELECT 
        c.CategoryID,
        c.CategoryName,
        c.ParentCategoryID,
        ch.Level + 1,
        CAST(ch.CategoryPath + ' > ' + c.CategoryName AS VARCHAR(255)),
        CAST(ch.CategoryIDPath + '.' + CAST(c.CategoryID AS VARCHAR(10)) AS VARCHAR(255))
    FROM 
        Categories c
        INNER JOIN CategoriesHierarchie ch ON c.ParentCategoryID = ch.CategoryID
)

SELECT 
    ch.CategoryID,
    ch.CategoryName,
    ch.ParentCategoryID,
    parent.CategoryName AS ParentCategoryName,
    ch.Level,
    ch.CategoryPath,
    ch.CategoryIDPath,
    
    -- Nombre de sous-catégories directes
    (
        SELECT COUNT(*) 
        FROM Categories sub 
        WHERE sub.ParentCategoryID = ch.CategoryID
    ) AS DirectSubcategories,
    
    -- Nombre total de produits dans cette catégorie
    (
        SELECT COUNT(*) 
        FROM Products p 
        WHERE p.CategoryID = ch.CategoryID
    ) AS DirectProducts,
    
    -- Nombre total de produits dans cette catégorie et ses sous-catégories
    (
        SELECT COUNT(*) 
        FROM Products p 
        JOIN Categories subcat ON p.CategoryID = subcat.CategoryID
        WHERE subcat.CategoryID = ch.CategoryID 
           OR subcat.ParentCategoryID = ch.CategoryID
           OR EXISTS (
               SELECT 1 
               FROM Categories subsubcat 
               WHERE subsubcat.ParentCategoryID = ch.CategoryID
                  AND subcat.ParentCategoryID = subsubcat.CategoryID
           )
    ) AS TotalProducts,
    
    -- Statistiques de ventes pour cette catégorie
    COALESCE(cat_sales.TotalOrders, 0) AS CategoryOrders,
    COALESCE(cat_sales.TotalQuantity, 0) AS CategoryQuantity,
    COALESCE(cat_sales.TotalSales, 0) AS CategorySales,
    
    -- Statistiques de ventes pour cette catégorie et ses sous-catégories
    COALESCE(all_sales.TotalOrders, 0) AS TotalOrders,
    COALESCE(all_sales.TotalQuantity, 0) AS TotalQuantity,
    COALESCE(all_sales.TotalSales, 0) AS TotalSales
FROM 
    CategoriesHierarchie ch
    LEFT JOIN Categories parent ON ch.ParentCategoryID = parent.CategoryID
    
    -- Jointure pour les statistiques de ventes de cette catégorie uniquement
    LEFT JOIN (
        SELECT 
            p.CategoryID,
            COUNT(DISTINCT o.OrderID) AS TotalOrders,
            SUM(od.Quantity) AS TotalQuantity,
            SUM(od.Quantity * od.UnitPrice) AS TotalSales
        FROM 
            Products p
            JOIN OrderDetails od ON p.ProductID = od.ProductID
            JOIN Orders o ON od.OrderID = o.OrderID
        WHERE 
            o.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
        GROUP BY 
            p.CategoryID
    ) cat_sales ON ch.CategoryID = cat_sales.CategoryID
    
    -- Jointure pour les statistiques de ventes de cette catégorie et ses sous-catégories
    LEFT JOIN (
        SELECT 
            c.CategoryID,
            COUNT(DISTINCT o.OrderID) AS TotalOrders,
            SUM(od.Quantity) AS TotalQuantity,
            SUM(od.Quantity * od.UnitPrice) AS TotalSales
        FROM 
            Categories c
            JOIN Categories subc ON subc.CategoryID = c.CategoryID 
                                OR subc.ParentCategoryID = c.CategoryID
                                OR EXISTS (
                                    SELECT 1 
                                    FROM Categories subsubc 
                                    WHERE subsubc.ParentCategoryID = c.CategoryID
                                       AND subc.ParentCategoryID = subsubc.CategoryID
                                )
            JOIN Products p ON subc.CategoryID = p.CategoryID
            JOIN OrderDetails od ON p.ProductID = od.ProductID
            JOIN Orders o ON od.OrderID = o.OrderID
        WHERE 
            o.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
        GROUP BY 
            c.CategoryID
    ) all_sales ON ch.CategoryID = all_sales.CategoryID
ORDER BY 
    ch.CategoryIDPath; 