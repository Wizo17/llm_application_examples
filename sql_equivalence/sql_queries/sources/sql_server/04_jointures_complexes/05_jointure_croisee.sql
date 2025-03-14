-- Requête avec jointures complexes : Jointure croisée (CROSS JOIN)
-- Cette requête génère un calendrier de disponibilité des salles de réunion

-- Déclaration des variables pour la période
DECLARE @StartDate DATE = '2023-01-01';
DECLARE @EndDate DATE = '2023-01-31';

-- CTE pour générer une séquence de dates
WITH DateSequence AS (
    SELECT 
        DATEADD(DAY, number, @StartDate) AS Date
    FROM 
        master.dbo.spt_values
    WHERE 
        type = 'P' 
        AND DATEADD(DAY, number, @StartDate) <= @EndDate
),

-- CTE pour les créneaux horaires
TimeSlots AS (
    SELECT 
        SlotID,
        StartTime,
        EndTime,
        DATEDIFF(MINUTE, StartTime, EndTime) AS DurationMinutes
    FROM 
        MeetingTimeSlots
    WHERE 
        IsActive = 1
),

-- CTE pour les salles de réunion
MeetingRooms AS (
    SELECT 
        RoomID,
        RoomName,
        Building,
        Floor,
        Capacity,
        HasVideoConference,
        HasProjector
    FROM 
        MeetingRooms
    WHERE 
        IsActive = 1
),

-- CTE pour les réservations existantes
ExistingBookings AS (
    SELECT 
        RoomID,
        BookingDate,
        TimeSlotID,
        MeetingID,
        EmployeeID,
        Purpose
    FROM 
        RoomBookings
    WHERE 
        BookingDate BETWEEN @StartDate AND @EndDate
        AND IsCancelled = 0
)

-- Génération du calendrier complet avec disponibilité
SELECT 
    d.Date,
    DATENAME(WEEKDAY, d.Date) AS DayOfWeek,
    CASE WHEN DATENAME(WEEKDAY, d.Date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END AS IsWeekend,
    ts.SlotID,
    ts.StartTime,
    ts.EndTime,
    ts.DurationMinutes,
    mr.RoomID,
    mr.RoomName,
    mr.Building,
    mr.Floor,
    mr.Capacity,
    mr.HasVideoConference,
    mr.HasProjector,
    
    -- Informations sur la réservation si elle existe
    eb.MeetingID,
    eb.EmployeeID,
    CASE WHEN eb.MeetingID IS NULL THEN 'Disponible' ELSE 'Réservé' END AS Status,
    eb.Purpose,
    
    -- Informations sur l'employé qui a réservé
    e.FirstName + ' ' + e.LastName AS BookedBy,
    e.Email AS BookedByEmail,
    e.DepartmentName
FROM 
    DateSequence d
    CROSS JOIN TimeSlots ts
    CROSS JOIN MeetingRooms mr
    LEFT JOIN ExistingBookings eb ON d.Date = eb.BookingDate 
                                  AND ts.SlotID = eb.TimeSlotID 
                                  AND mr.RoomID = eb.RoomID
    LEFT JOIN (
        SELECT 
            e.EmployeeID,
            e.FirstName,
            e.LastName,
            e.Email,
            d.DepartmentName
        FROM 
            Employees e
            JOIN Departments d ON e.DepartmentID = d.DepartmentID
    ) e ON eb.EmployeeID = e.EmployeeID
WHERE
    -- Filtrer les week-ends si nécessaire
    (DATENAME(WEEKDAY, d.Date) NOT IN ('Saturday', 'Sunday') OR @IncludeWeekends = 1)
ORDER BY 
    mr.Building,
    mr.Floor,
    mr.RoomName,
    d.Date,
    ts.StartTime; 