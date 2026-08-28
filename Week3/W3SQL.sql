DECLARE @TaskUID INT = 5347479;
SELECT * 
FROM LatestProofVersionView AS LPVV
WHERE LPVV.TaskUID = @TaskUID;

SELECT *
FROM WorkReportView AS WRV;

DECLARE @AccountUID INT = 78116;

WITH FilteredRequests AS (
    SELECT
        wr.WorkRequestUID,
        DATEFROMPARTS(YEAR(wr.CompletedDate), MONTH(wr.CompletedDate), 1) AS CompletedMonth,
        CASE WHEN CAST(wr.CompletedDate AS DATE) <= CAST(wr.DueDate AS DATE)
             THEN 1 ELSE 0 END AS IsOnTime
    FROM dbo.WorkRequest AS wr
    WHERE wr.AccountUID = @AccountUID
        AND wr.Deleted = 0
        AND wr.CompletedDate IS NOT NULL
        AND wr.DueDate IS NOT NULL
),
MonthlyTotals AS (
    SELECT
        CompletedMonth,
        COUNT(*)      AS TotalCompleted,
        SUM(IsOnTime) AS OnTimeCount
    FROM FilteredRequests
    GROUP BY CompletedMonth
)
SELECT
    CompletedMonth,
    FORMAT(CompletedMonth, 'yyyy-MM')                                    AS CompletedMonthLabel,
    TotalCompleted,
    OnTimeCount,
    CAST(OnTimeCount AS DECIMAL(10,2)) / NULLIF(TotalCompleted, 0) * 100 AS OnTimeRatePercent
FROM MonthlyTotals
ORDER BY CompletedMonth; --E1

WITH RankedProofs AS (
    SELECT
        p.ProofUID,
        p.TaskUID,
        p.VersionNumber,
        p.CreatedDateTime,
        ROW_NUMBER() OVER (
            PARTITION BY p.TaskUID
            ORDER BY p.VersionNumber DESC, p.CreatedDateTime DESC, p.ProofUID DESC
        ) AS rn
    FROM dbo.Proof AS p
    INNER JOIN dbo.Task AS t
        ON t.TaskUID = p.TaskUID
    WHERE t.AccountUID = @AccountUID
        AND t.Deleted = 0
        AND p.Deleted = 0
)
SELECT
    TaskUID,
    ProofUID  AS LatestProofUID,
    VersionNumber AS LatestVersionNumber,
    CreatedDateTime AS LatestProofCreatedDateTime
FROM RankedProofs
WHERE rn = 1; --E2

DECLARE @AsOf DATETIME = GETDATE(); -- reference point for whatever status hasn't closed yet

WITH SampleRequests AS (
    SELECT TOP (10) wr.WorkRequestUID, wr.CompletedDate
    FROM dbo.WorkRequest AS wr
    WHERE wr.AccountUID = @AccountUID
        AND wr.Deleted = 0
    ORDER BY wr.WorkRequestUID
),
LogWithLag AS (
    SELECT
        wisl.WorkItemUID,
        wisl.StatusTypeID,
        wisl.ChangedDateTime,
        LAG(wisl.ChangedDateTime) OVER (
            PARTITION BY wisl.WorkItemUID
            ORDER BY wisl.ChangedDateTime
        ) AS PrevChangedDateTime,
        LAG(wisl.StatusTypeID) OVER (
            PARTITION BY wisl.WorkItemUID
            ORDER BY wisl.ChangedDateTime
        ) AS PrevStatusTypeID,
        ROW_NUMBER() OVER (
            PARTITION BY wisl.WorkItemUID
            ORDER BY wisl.ChangedDateTime DESC
        ) AS rn_desc
    FROM dbo.WorkItemStatusLog AS wisl
    INNER JOIN SampleRequests AS sr
        ON sr.WorkRequestUID = wisl.WorkItemUID   -- shared PK: WorkRequestUID *is* the WorkItemUID
),

-- Closed intervals: every status change EXCEPT the currently-active one.
-- Attribution trap: LAG pulls the PREVIOUS row's timestamp/status onto the
-- current row. The time between PrevChangedDateTime and ChangedDateTime was
-- spent in PrevStatusTypeID, not in the current row's own StatusTypeID.
-- Using StatusTypeID here instead of PrevStatusTypeID would silently
-- attribute every duration to the status the item moved INTO, not the one
-- it was leaving -- same shape of bug as the WorkRequest/Project INNER JOIN
-- one two exercises back: quietly wrong, not loudly wrong.
ClosedIntervals AS (
    SELECT
        WorkItemUID,
        PrevStatusTypeID   AS StatusTypeID,
        PrevChangedDateTime AS StatusStartDateTime,

        DATEDIFF(MINUTE, PrevChangedDateTime, ChangedDateTime) / 1440.0 AS DaysInStatus,
        CAST(0 AS BIT) AS IsCurrentStatus
    FROM LogWithLag
    WHERE PrevChangedDateTime IS NOT NULL  -- drops each item's very first log row: nothing precedes it to close out
),

-- Open interval: the most recent status per item has no successor row in
-- the log, so LAG never produces a duration for it at all -- it would be
-- silently missing from the result set entirely, not just miscounted.
-- Decision made here, stated explicitly rather than left implicit:
--   - If the request has a CompletedDate, treat that as the close of the
--     final status (the item can't still be "in progress" after completion).
--   - Otherwise, treat the status as still running and measure it up to
--     @AsOf (now).
-- The alternative -- leaving this interval out, or leaving its end date
-- NULL -- would understate total logged time and make per-item
-- SUM(DaysInStatus) fail to reconcile against the item's actual age.
CurrentInterval AS (
    SELECT
        l.WorkItemUID,
        l.PrevStatusTypeID,
        l.PrevChangedDateTime AS StatusStartDateTime,
        COALESCE(sr.CompletedDate, @AsOf) AS StatusEndDateTime,
        DATEDIFF(MINUTE, l.ChangedDateTime, COALESCE(sr.CompletedDate, @AsOf)) / 1440.0 AS DaysInStatus,
        CAST(1 AS BIT) AS IsCurrentStatus
    FROM LogWithLag AS l
    INNER JOIN SampleRequests AS sr
        ON sr.WorkRequestUID = l.WorkItemUID
    WHERE l.rn_desc = 1
)

SELECT * FROM ClosedIntervals
UNION ALL
SELECT * FROM CurrentInterval
ORDER BY WorkItemUID, StatusStartDateTime;

SELECT LAG(WISL.WorkItemStatusLogUID) OVER (
PARTITION BY WISL.WorkItemUID ORDER BY WISL.TimeStamp)
FROM WorkItemStatusLog AS WISL
WHERE AccountUID = 78116;



