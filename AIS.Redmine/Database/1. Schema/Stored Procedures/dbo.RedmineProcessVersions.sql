SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RedmineProcessVersions]
	@xml XML,
	@total INT OUTPUT,
	@added INT OUTPUT,
	@updated INT OUTPUT,
	@deleted INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE
		@i INT

	-- init
	BEGIN
		CREATE TABLE #versions (
			id INT,
			projectId INT,
			[name] NVARCHAR(100) COLLATE DATABASE_DEFAULT,
			--[description] NVARCHAR(1000) COLLATE DATABASE_DEFAULT,
			[status] NVARCHAR(100) COLLATE DATABASE_DEFAULT,
			dueDate DATE,
			createdOn DATETIMEOFFSET(0),
			updatedOn DATETIMEOFFSET(0),
		
			_isClosed BIT,
			_versionId INT
		)
	END

	-- FILL
	BEGIN
		INSERT #versions (
		    id,
		    projectId,
		    name,
		    status,
		    dueDate,
		    createdOn,
		    updatedOn
		)
		SELECT 
			c.value('id[1]', 'int'),
			c.value('project[1]/@id[1]', 'int'),
			c.value('name[1]', 'nvarchar(100)'),
			--NULLIF(c.value('description[1]', 'nvarchar(1000)'), ''),
			c.value('status[1]', 'nvarchar(100)'),
			c.value('due_date[1]', 'date'),
			c.value('created_on[1]', 'datetimeoffset(0)'),
			c.value('updated_on[1]', 'datetimeoffset(0)')
		FROM @xml.nodes('/versions/version') T(c)
		SET @total = @@ROWCOUNT
		PRINT STR(@total) + ' rows in xml'

		UPDATE #versions
		SET _isClosed = CASE WHEN [status] IN ('closed', 'locked') THEN 1 ELSE 0 END
		WHERE _isClosed IS NULL
	END

	-- map
	BEGIN
		UPDATE d
		SET d._versionId = x.Id
		FROM #versions d
			JOIN dbo.IssueVersion x ON x.Id = d.id
		WHERE d._versionId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows mapped'
	END

	-- apply
	BEGIN
		UPDATE x
		SET x.Name = d.name,
			x.ProjectId = d.projectId,
			x.IsClosed = d._isClosed,
			x.RedmineCreated = d.createdOn,
			x.RedmineUpdated = d.updatedOn,
			x.IsDeleted = 0,
			x.DueDate = d.dueDate,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #versions d
			JOIN dbo.IssueVersion x ON x.Id = d._versionId
		WHERE x.[Name] <> d.[name]
			OR x.ProjectId <> d.projectId
			OR x.IsClosed <> d._isClosed
			OR x.RedmineCreated <> d.createdOn
			OR x.RedmineUpdated <> d.updatedOn
			OR x.IsDeleted = 1
			OR ISNULL(x.DueDate, '19000101') <> ISNULL(d.DueDate, '19000101')
		SET @updated = @@ROWCOUNT
		PRINT STR(@updated) + ' rows changed'

		INSERT dbo.IssueVersion (
		    Id,
		    Name,
			ProjectId,
		    DueDate,
		    IsClosed,
		    IsDeleted,
		    RedmineCreated,
		    RedmineUpdated,
		    Created,
		    Updated
		)
		SELECT
			d.Id,
			d.[name],
			d.projectId,
			d.dueDate,
			d._isClosed,
			0,
			d.createdOn,
			d.updatedOn,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #versions d
		WHERE d._versionId IS NULL
		SET @added = @@ROWCOUNT
		PRINT STR(@added) + ' rows added'

		-- store last received date
		UPDATE x
		SET x.LastReceivedDate = SYSDATETIMEOFFSET()
		FROM #versions d
			JOIN dbo.IssueVersion x ON x.Id = d.id
		WHERE 1=1
    END

	DROP TABLE #versions 
END
GO
