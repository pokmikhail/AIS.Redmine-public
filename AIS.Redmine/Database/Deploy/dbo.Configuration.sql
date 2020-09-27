SET NOCOUNT ON

CREATE TABLE #temptable
(
    [Code] NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    [Value] NVARCHAR(2000) COLLATE DATABASE_DEFAULT,
    [Name] NVARCHAR(200) COLLATE DATABASE_DEFAULT,
    [Description] NVARCHAR(2000) COLLATE DATABASE_DEFAULT
)

INSERT #temptable ([Code], [Value], [Name], [Description])
VALUES
(N'Redmine:Url', N'https://redmine.aisgorod.ru/', N'Адрес сайта Redmine', NULL),
(N'Redmine:ApiKey', N'----------------------------------------', N'API Key для обмена с Redmine', NULL)

INSERT #temptable ([Code], [Value], [Name], [Description])
VALUES
(N'System:IssueMaxUpdated', N'1900-01-01', N'Дата последнего обновления задачи в Redmine.', 'Для работы метода получения обновлённых задач.'),
(N'System:TimeEntryMaxUpdated', N'1900-01-01', N'Дата последнего обновления трудозатрат в Redmine.', 'Для работы метода получения обновлённых трудозатрат.')

-- check names
UPDATE x
SET x.Name = d.Name,
	x.Description = d.Description,
	x.Updated = SYSDATETIMEOFFSET()
FROM #temptable d
	JOIN dbo.Configuration x ON x.Code = d.Code
WHERE d.Name <> x.Name
	OR COALESCE(d.Description, '~') <> COALESCE(x.Description, '~')
PRINT STR(@@ROWCOUNT) + ' rows updated'

-- add missing params with default values
INSERT dbo.Configuration (
	Code ,
    Value ,
    Name ,
    Description ,
    Created ,
    Updated
)
SELECT
	d.Code ,
	d.Value ,
    d.Name ,
    d.Description,
	SYSDATETIMEOFFSET(),
	SYSDATETIMEOFFSET()
FROM #temptable d
WHERE NOT EXISTS (
		SELECT 1
		FROM dbo.Configuration x
		WHERE x.Code = d.Code
	)

PRINT STR(@@ROWCOUNT) + ' rows added'

DROP TABLE #temptable