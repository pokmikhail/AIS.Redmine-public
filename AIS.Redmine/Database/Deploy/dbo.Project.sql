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
    [Code] NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    [Name] NVARCHAR(200) COLLATE DATABASE_DEFAULT
)

INSERT #temptable ([Id], [Code], [Name])
SELECT 139, N'rias-root', N'Проекты Ульяновск'

-- init missing projects
INSERT dbo.Project (
    Id,
    Code,
    [Name],
    RedmineName,
    HasRevisions,
    HasVersions,
    IsDeleted,
    RedmineCreated,
    Created,
    Updated
)
SELECT
    d.Id,
    d.Code,
    d.[Name],
    d.[Name],
    1,
    1,
    0,
    '19000101',
    SYSDATETIMEOFFSET(),
    SYSDATETIMEOFFSET()
FROM #temptable d
WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Project x
        WHERE x.Code = d.Code
    )

PRINT STR(@@ROWCOUNT) + ' rows added'

DROP TABLE #temptable