-- Requête avec jointures complexes : Jointures avec agrégation
-- Cette requête analyse les performances des vendeurs par rapport aux objectifs de vente

WITH 
-- Ventes réelles par vendeur et par mois
VentesReelles AS (
    SELECT 
        E.EmployeeID,
        E.FirstName + ' ' + E.LastName AS EmployeeName,
        YEAR(O.OrderDate) AS OrderYear,
        MONTH(O.OrderDate) AS OrderMonth,
        FORMAT(DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1), 'MMM yyyy') AS MonthYear,
        COUNT(DISTINCT O.OrderID) AS NombreCommandes,
        COUNT(DISTINCT O.CustomerID) AS NombreClients,
        SUM(OD.Quantity) AS QuantiteTotale,
        SUM(OD.Quantity * OD.UnitPrice) AS ChiffreAffaires
    FROM 
        Employees E
        JOIN Orders O ON E.EmployeeID = O.EmployeeID
        JOIN OrderDetails OD ON O.OrderID = OD.OrderID
    WHERE 
        O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
        AND E.DepartmentID = 2 -- Département des ventes
    GROUP BY 
        E.EmployeeID,
        E.FirstName + ' ' + E.LastName,
        YEAR(O.OrderDate),
        MONTH(O.OrderDate),
        FORMAT(DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1), 'MMM yyyy')
),

-- Objectifs de vente par vendeur et par mois
ObjectifsVente AS (
    SELECT 
        EmployeeID,
        YEAR(PeriodDate) AS TargetYear,
        MONTH(PeriodDate) AS TargetMonth,
        SalesTarget AS ObjectifCA,
        ClientsTarget AS ObjectifClients,
        OrdersTarget AS ObjectifCommandes
    FROM 
        SalesTargets
    WHERE 
        PeriodDate BETWEEN '2023-01-01' AND '2023-12-31'
),

-- Statistiques par région
StatsRegion AS (
    SELECT 
        R.RegionID,
        R.RegionName,
        COUNT(DISTINCT O.OrderID) AS NombreCommandes,
        COUNT(DISTINCT O.CustomerID) AS NombreClients,
        SUM(OD.Quantity) AS QuantiteTotale,
        SUM(OD.Quantity * OD.UnitPrice) AS ChiffreAffaires
    FROM 
        Regions R
        JOIN Customers C ON R.RegionID = C.RegionID
        JOIN Orders O ON C.CustomerID = O.CustomerID
        JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        JOIN Employees E ON O.EmployeeID = E.EmployeeID
    WHERE 
        O.OrderDate BETWEEN '2023-01-01' AND '2023-12-31'
        AND E.DepartmentID = 2 -- Département des ventes
    GROUP BY 
        R.RegionID,
        R.RegionName
),

-- Affectation des vendeurs aux régions
VendeursRegions AS (
    SELECT 
        ER.EmployeeID,
        ER.RegionID,
        R.RegionName,
        ER.IsMainRegion
    FROM 
        EmployeeRegions ER
        JOIN Regions R ON ER.RegionID = R.RegionID
    WHERE 
        ER.AssignmentDate <= '2023-12-31'
        AND (ER.EndDate IS NULL OR ER.EndDate > '2023-01-01')
)

-- Requête principale
SELECT 
    VR.EmployeeID,
    VR.EmployeeName,
    VR.OrderYear,
    VR.OrderMonth,
    VR.MonthYear,
    
    -- Données de ventes réelles
    VR.NombreCommandes,
    VR.NombreClients,
    VR.ChiffreAffaires,
    
    -- Objectifs de vente
    OV.ObjectifCommandes,
    OV.ObjectifClients,
    OV.ObjectifCA,
    
    -- Calcul des performances par rapport aux objectifs
    CAST(VR.NombreCommandes AS FLOAT) / NULLIF(OV.ObjectifCommandes, 0) * 100 AS PourcentageObjectifCommandes,
    CAST(VR.NombreClients AS FLOAT) / NULLIF(OV.ObjectifClients, 0) * 100 AS PourcentageObjectifClients,
    CAST(VR.ChiffreAffaires AS FLOAT) / NULLIF(OV.ObjectifCA, 0) * 100 AS PourcentageObjectifCA,
    
    -- Informations sur les régions
    STRING_AGG(CASE WHEN VReg.IsMainRegion = 1 THEN VReg.RegionName + ' (principale)' ELSE VReg.RegionName END, ', ') AS Regions,
    
    -- Statistiques par région principale
    SR.NombreCommandes AS CommandesRegionPrincipale,
    SR.NombreClients AS ClientsRegionPrincipale,
    SR.ChiffreAffaires AS CARegionPrincipale,
    
    -- Part de marché dans la région principale
    CAST(VR.ChiffreAffaires AS FLOAT) / NULLIF(SR.ChiffreAffaires, 0) * 100 AS PartMarcheRegion
FROM 
    VentesReelles VR
    LEFT JOIN ObjectifsVente OV ON VR.EmployeeID = OV.EmployeeID 
                               AND VR.OrderYear = OV.TargetYear 
                               AND VR.OrderMonth = OV.TargetMonth
    LEFT JOIN VendeursRegions VReg ON VR.EmployeeID = VReg.EmployeeID
    LEFT JOIN StatsRegion SR ON VReg.RegionID = SR.RegionID AND VReg.IsMainRegion = 1
GROUP BY 
    VR.EmployeeID,
    VR.EmployeeName,
    VR.OrderYear,
    VR.OrderMonth,
    VR.MonthYear,
    VR.NombreCommandes,
    VR.NombreClients,
    VR.ChiffreAffaires,
    OV.ObjectifCommandes,
    OV.ObjectifClients,
    OV.ObjectifCA,
    SR.NombreCommandes,
    SR.NombreClients,
    SR.ChiffreAffaires
ORDER BY 
    VR.EmployeeName,
    VR.OrderYear,
    VR.OrderMonth; 