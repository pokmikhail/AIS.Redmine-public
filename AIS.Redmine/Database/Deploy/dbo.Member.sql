/*
    pre-configure projects
*/

SET NOCOUNT ON

IF NOT EXISTS(
    SELECT 1
    FROM dbo.Configuration
    WHERE Code = 'Redmine:Url'
        AND Value LIKE '%/redmine.aisgorod.ru/%'
    )
BEGIN
    PRINT 'not needed'
    RETURN
END

CREATE TABLE #temptable
(
    [Id] INT,
    [Name] NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    [Login] NVARCHAR(200) COLLATE DATABASE_DEFAULT
)

INSERT #temptable ([Id], [Name], [Login])
SELECT 2, N'Аноним', N'[ none ]'

-- init missing projects
INSERT dbo.Member (
    RedmineId,
    [Name],
    NameAndInitials,
    RedmineLogin,
    IsDeleted,
    RedmineCreated,
    Created,
    Updated
)
SELECT
    d.Id,
    d.[Name],
    d.[Name],
    d.[Login],
    0,
    '19000101',
    SYSDATETIMEOFFSET(),
    SYSDATETIMEOFFSET()
FROM #temptable d
WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Member x
        WHERE x.RedmineId = d.Id
    )

PRINT STR(@@ROWCOUNT) + ' rows added'

DROP TABLE #temptable