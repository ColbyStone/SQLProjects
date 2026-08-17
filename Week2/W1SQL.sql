SELECT TOP (30) AccountUID, Name, SubmittedDate, DueDate
FROM dbo.[WorkRequest]
WHERE AccountUID = 78116; --E1

SELECT TOP (30) AccountUID, Name, SubmittedDate, DueDate
FROM dbo.[WorkRequest]
WHERE AccountUID = 78116 AND Deleted = 0; --E1

SELECT *
FROM dbo.[WorkRequest]
WHERE AccountUID = 78116; --Just a helper

SELECT COUNT(*) FROM dbo.[WorkRequest] WHERE AccountUID = 78116;
SELECT COUNT(*) FROM dbo.[WorkRequest] WHERE AccountUID = 78116 AND Deleted = 0;
SELECT COUNT(*) FROM dbo.[WorkRequest] WHERE AccountUID = 78116 AND Deleted = 0 AND Archived = 0; -- E2

SELECT TOP (30) AccountUID, WorkRequestStatusTypeID, DueDate, CompletedDate, DeclinedByUserUID, DeclinedDateTime, DeclinedMessage
FROM dbo.[WorkRequest]
WHERE AccountUID = 78116; --E3 / E4

SELECT TOP (30) AccountUID, DeclinedByUserUID, DeclinedDateTime, DeclinedMessage
FROM dbo.[WorkRequest]
WHERE AccountUID = 78116; --E5

SELECT *
FROM dbo.[UserView]
WHERE AccountUID = 78116; --E6

SELECT TOP (7) RequestFormUID
FROM dbo.[WorkRequest]
WHERE AccountUID = 78116; --E7

SELECT TOP (7) DATEDIFF(DAY, 0, GETUTCDATE())
FROM dbo.[WorkRequest]
WHERE AccountUID = 78116; --E8

SELECT *
FROM dbo.[Role]
WHERE AccountUID = 78116; --E9

SELECT *
FROM dbo.[Role]
WHERE AccountUID = 78116 AND SeatTypeID = 1; --E10, What is a seat type?