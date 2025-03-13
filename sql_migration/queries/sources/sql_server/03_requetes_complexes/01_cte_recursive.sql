-- Requête complexe : CTE récursive
-- Cette requête utilise une CTE récursive pour générer une hiérarchie d'employés

WITH EmployeeHierarchy AS (
    -- Cas de base : employés de niveau supérieur (sans manager)
    SELECT 
        EmployeeID,
        FirstName,
        LastName,
        Title,
        ReportsTo,
        0 AS HierarchyLevel,
        CAST(FirstName + ' ' + LastName AS VARCHAR(255)) AS HierarchyPath
    FROM 
        Employees
    WHERE 
        ReportsTo IS NULL
    
    UNION ALL
    
    -- Cas récursif : employés avec un manager
    SELECT 
        e.EmployeeID,
        e.FirstName,
        e.LastName,
        e.Title,
        e.ReportsTo,
        eh.HierarchyLevel + 1,
        CAST(eh.HierarchyPath + ' > ' + e.FirstName + ' ' + e.LastName AS VARCHAR(255))
    FROM 
        Employees e
        INNER JOIN EmployeeHierarchy eh ON e.ReportsTo = eh.EmployeeID
)

SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Title,
    ReportsTo,
    HierarchyLevel,
    REPLICATE('    ', HierarchyLevel) + FirstName + ' ' + LastName AS FormattedName,
    HierarchyPath
FROM 
    EmployeeHierarchy
ORDER BY 
    HierarchyPath; 