-- Requête moyenne : Utilisation de PIVOT pour transformer les lignes en colonnes
-- Cette requête crée un rapport des ventes trimestrielles par catégorie

SELECT 
    CategoryName,
    [Q1] AS 'Premier Trimestre',
    [Q2] AS 'Deuxième Trimestre',
    [Q3] AS 'Troisième Trimestre',
    [Q4] AS 'Quatrième Trimestre',
    ([Q1] + [Q2] + [Q3] + [Q4]) AS 'Total Annuel'
FROM (
    SELECT 
        C.CategoryName,
        'Q' + CAST(DATEPART(QUARTER, O.OrderDate) AS VARCHAR) AS Quarter,
        SUM(OD.Quantity * OD.UnitPrice) AS Sales
    FROM 
        Orders O
        JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        JOIN Products P ON OD.ProductID = P.ProductID
        JOIN Categories C ON P.CategoryID = C.CategoryID
    WHERE 
        O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        C.CategoryName,
        DATEPART(QUARTER, O.OrderDate)
) AS SourceTable
PIVOT (
    SUM(Sales)
    FOR Quarter IN ([Q1], [Q2], [Q3], [Q4])
) AS PivotTable
ORDER BY 
    CategoryName; 