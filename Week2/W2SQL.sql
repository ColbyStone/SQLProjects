--Orientation

SELECT *
FROM dbo.[WorkRequest]
WHERE AccountUID = 78116;

SELECT * 
FROM dbo.[Task]
WHERE AccountUID = 78116;

SELECT TOP(30) Task.ProjectUID, Task.Name, Task.CampaignUID, Task.WorkGroupUID, Task.WorkRequestUID
FROM dbo.[Task]
WHERE AccountUID = 78116;

SELECT *
FROM dbo.[Proof]
WHERE AccountUID = 78116;

SELECT *
FROM dbo.[ReviewReportView]
WHERE AccountUID = 78116;

--Exercises

SELECT wr.WorkRequestUID, wr.Name, p.FirstName + N' ' + p.LastName AS FullName,
       p.Email, wr.WorkRequestStatusTypeID, wr.SubmittedDate, wr.CreatedByUserUID
FROM       dbo.WorkRequest        AS wr
JOIN dbo.[User] as u ON u.UserUID = wr.CreatedByUserUID
JOIN       dbo.Account  AS a ON a.AccountUID = u.AccountUID
LEFT JOIN  dbo.[Profile] AS p
       ON p.ProfileUID = COALESCE(u.ProfileUID, a.SupportProfileUID)

WHERE  wr.AccountUID = 78116 AND wr.Deleted = 0 --E1

--E2
SELECT t.TaskUID, t.Name AS TaskName, t.ProjectUID, p.ProjectUID AS Project_ProjectUID, p.Name AS ProjectName
FROM dbo.[Task] AS t
INNER JOIN dbo.[Project] AS p
ON p.ProjectUID = t.ProjectUID
WHERE t.AccountUID = 78116 AND t.Deleted = 0;

SELECT t.TaskUID, t.Name AS TaskName, t.ProjectUID, p.ProjectUID AS Project_ProjectUID, p.Name AS ProjectName
FROM dbo.[Task] AS t
LEFT JOIN dbo.[Project] AS p
ON p.ProjectUID = t.ProjectUID
WHERE t.AccountUID = 78116 AND t.Deleted = 0;

--END OF E2

--E3
DECLARE @AccountUIDS TABLE (AccountUID INT PRIMARY KEY)
INSERT INTO @AccountUIDS (AccountUID) VALUES (78116)
SELECT p.AccountUID, COUNT(*) AS TotalProofVers, COUNT(DISTINCT p.TaskUID) AS DistinctProofTask, CAST(COUNT(*) AS DECIMAL(10,2)) / NULLIF(COUNT(DISTINCT p.TaskUID), 0) AS VersionsPerProof
FROM dbo.[Proof] AS p
INNER JOIN @AccountUIDs AS a ON a.AccountUID = p.AccountUID
WHERE p.Deleted = 0
GROUP BY p.AccountUID
ORDER BY VersionsPerProof DESC;
--END OF E3

--E4
DECLARE @AccountUID INT = 78116;
SELECT
    DATEFROMPARTS(YEAR(wr.SubmittedDate), MONTH(wr.SubmittedDate), 1) AS SubmittedMonth,
    FORMAT(DATEFROMPARTS(YEAR(wr.SubmittedDate), MONTH(wr.SubmittedDate), 1), 'yyyy-MM') AS SubmittedMonthLabel,
    COUNT(*)                                                     AS CompletedRequestCount,
    AVG(DATEDIFF(day, wr.SubmittedDate, wr.CompletedDate) * 1.0) AS AvgDaysToComplete
FROM dbo.WorkRequest AS wr
WHERE wr.AccountUID = @AccountUID
    AND wr.Deleted = 0
    AND wr.SubmittedDate IS NOT NULL
    AND wr.CompletedDate IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(wr.SubmittedDate), MONTH(wr.SubmittedDate), 1)
ORDER BY SubmittedMonth;
--END OF E4

--E5
SELECT
    u.UserUID,
    SUM(te.NumberOfSeconds) / 3600.0 AS TotalHours
FROM dbo.UserWorkItemTimeLog AS te
INNER JOIN dbo.[User] AS u
    ON u.UserUID = te.UserUID
WHERE te.AccountUID = 78116
    AND te.Deleted = 0
GROUP BY u.UserUID
HAVING SUM(te.NumberOfSeconds) / 3600.0 > 40
ORDER BY TotalHours DESC;
-- END of E5

--E6
SELECT
    wr.WorkRequestUID,
    wr.Name             AS RequestName,
    COUNT(c.CommentUID) AS CommentCount
FROM dbo.WorkRequest AS wr
LEFT JOIN dbo.CommentList AS cl
    ON cl.CommentListUID = wr.CommentListUID
    AND cl.Deleted = 0
LEFT JOIN dbo.CommentListComment AS clc          -- bridge/junction table
    ON clc.CommentListUID = cl.CommentListUID
    AND clc.Deleted = 0
LEFT JOIN dbo.Comment AS c
    ON c.CommentUID = clc.CommentUID
    AND c.Deleted = 0
WHERE wr.AccountUID = 78116
    AND wr.Deleted = 0
GROUP BY wr.WorkRequestUID, wr.Name
ORDER BY wr.WorkRequestUID;

SELECT
    wr.WorkRequestUID,
    wr.Name             AS RequestName,
    COUNT(c.CommentUID) AS CommentCount
FROM dbo.WorkRequest AS wr
LEFT JOIN dbo.CommentList AS cl
    ON cl.CommentListUID = wr.CommentListUID
    AND cl.Deleted = 0
LEFT JOIN dbo.CommentListComment AS clc          -- bridge/junction table
    ON clc.CommentListUID = cl.CommentListUID
    AND clc.Deleted = 0
LEFT JOIN dbo.Comment AS c
    ON c.CommentUID = clc.CommentUID
    AND c.Deleted = 0
WHERE wr.AccountUID = 78116
    AND wr.Deleted = 0
    AND c.Deleted = 0
GROUP BY wr.WorkRequestUID, wr.Name
ORDER BY wr.WorkRequestUID;

--END OF e6

--E7

SELECT
    t.TaskUID,
    t.Name                       AS TaskName,
    COUNT(p.ProofUID)            AS ProofVersionCount,
    MAX(p.VersionNumber)         AS HighestVersionNumber
FROM dbo.Task AS t
LEFT JOIN dbo.Proof AS p
    ON p.TaskUID = t.TaskUID
    AND p.Deleted = 0
WHERE t.AccountUID = 78116
    AND t.Deleted = 0
GROUP BY t.TaskUID, t.Name
ORDER BY t.TaskUID;

--END OF e7

--E8

SELECT
    DATEFROMPARTS(YEAR(wr.CompletedDate), MONTH(wr.CompletedDate), 1) AS CompletedMonth,
    FORMAT(DATEFROMPARTS(YEAR(wr.CompletedDate), MONTH(wr.CompletedDate), 1), 'yyyy-MM') AS CompletedMonthLabel,
    COUNT(*) AS TotalCompleted,
    SUM(CASE WHEN wr.CompletedDate <= wr.DueDate THEN 1 ELSE 0 END) AS OnTimeCount,
    CAST(
        SUM(CASE WHEN wr.CompletedDate <= wr.DueDate THEN 1 ELSE 0 END) AS DECIMAL(10,2)
    ) / NULLIF(COUNT(*), 0) * 100 AS OnTimeRatePercent
FROM dbo.WorkRequest AS wr
WHERE wr.AccountUID = 78116
    AND wr.Deleted = 0
    AND wr.CompletedDate IS NOT NULL
    AND wr.DueDate IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(wr.CompletedDate), MONTH(wr.CompletedDate), 1)
ORDER BY CompletedMonth;
--END of E8

--E9
DECLARE @TaskUID INT = 5347457;


;WITH LatestProof AS (
    SELECT TOP (1) p.*
    FROM dbo.Proof AS p
    WHERE p.TaskUID = @TaskUID
        AND p.Deleted = 0
    ORDER BY p.VersionNumber DESC
)


SELECT
    lp.TaskUID,
    lp.ProofUID,
    lp.VersionNumber,
    pr.ProofRouteUID,
    rt.Name AS TierName,
    u.UserUID
FROM LatestProof AS lp

INNER JOIN dbo.ProofRoute AS pr
    ON pr.ProofRouteUID = lp.ProofRouteUID
INNER JOIN dbo.ProofRoute AS prt
    ON prt.ProofRouteUID = pr.ProofRouteUID

INNER JOIN dbo.RouteTier AS rt
    ON rt.RouteTierUID = prt.ProofRouteUID
INNER JOIN dbo.RouteTier AS rtr
    ON rtr.RouteTierUID = rt.RouteTierUID
INNER JOIN dbo.[User] AS u
    ON u.UserUID = rtr.RouteTierStatusTypeID;
--END OF E9

--E10

SELECT
    t.TaskUID,
    t.Name AS TaskName,
    t.WorkRequestUID,
    CASE
        WHEN t.WorkRequestUID IS NULL THEN 'Never linked to a WorkRequest'
        ELSE 'WorkRequestUID set, but no matching non-deleted WorkRequest row'
    END AS Reason
FROM dbo.Task AS t
LEFT JOIN dbo.WorkRequest AS wr
    ON wr.WorkRequestUID = t.WorkRequestUID
    AND wr.Deleted = 0
WHERE t.AccountUID = 78116
    AND t.Deleted = 0
    AND wr.WorkRequestUID IS NULL
    AND EXISTS (
        SELECT 1 FROM dbo.Proof AS p
        WHERE p.TaskUID = t.TaskUID AND p.Deleted = 0
    );


SELECT
    t.TaskUID,
    t.Name AS TaskName,
    t.WorkRequestUID
FROM dbo.Task AS t
WHERE t.AccountUID = 78116
    AND t.Deleted = 0
    AND EXISTS (
        SELECT 1 FROM dbo.Proof AS p
        WHERE p.TaskUID = t.TaskUID AND p.Deleted = 0
    )
    AND NOT EXISTS (
        SELECT 1 FROM dbo.WorkRequest AS wr
        WHERE wr.WorkRequestUID = t.WorkRequestUID AND wr.Deleted = 0
    );

--END OF E10

--END OF FILE 