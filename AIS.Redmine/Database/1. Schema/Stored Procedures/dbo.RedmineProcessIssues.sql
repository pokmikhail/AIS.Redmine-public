SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RedmineProcessIssues]
	@xml XML,
	@total INT OUTPUT,
	@added INT OUTPUT,
	@updated INT OUTPUT,
	@deleted INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE
		@i INT,
		@fakePriorityId INT,
		@fakeStatusId INT,
		@fakeTrackerId INT

	-- init
	BEGIN
		SELECT @fakePriorityId = Id
		FROM dbo.IssuePriority
		ORDER BY Sort DESC

		SELECT @fakeStatusId = Id
		FROM dbo.IssueStatus
		WHERE IsAccepted = 0 AND IsClosed = 0
		ORDER BY Id

		SELECT @fakeTrackerId = Id
		FROM dbo.IssueTracker
		ORDER BY Id

		CREATE TABLE #issues (
			id INT PRIMARY KEY,
			projectId INT,
			trackerId INT,
			statusId INT NOT NULL,
			priorityId INT,
			authorId INT,
			assignedToId INT,
			parentId INT,
			categoryId INT,
			versionId INT,
			[subject] NVARCHAR(2000) COLLATE DATABASE_DEFAULT,
			[description] NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
			startDate DATE,
			dueDate DATE,
			doneRatio INT,
			estimatedHours DECIMAL(9, 2),
			createdOn DATETIMEOFFSET(0),
			updatedOn DATETIMEOFFSET(0),
			closedOn DATETIMEOFFSET(0),
		
			_issueId INT,
			_authorMemberId INT,
			_assignedMemberId INT
		)

		CREATE TABLE #customFields (
			issueId INT NOT NULL,
			customFieldId INT NOT NULL,
			[value] NVARCHAR(2000) COLLATE DATABASE_DEFAULT,

			_customFieldId INT
		)

		CREATE TABLE #relations (
			id INT NOT NULL,
			issueId INT NOT NULL,
			issueToId INT NOT NULL,
			[type] NVARCHAR(200) COLLATE DATABASE_DEFAULT NOT NULL,
			[delay] INT,

			_relationId INT
		)
	END

	-- fill
	BEGIN
		INSERT #issues (
		    id,
		    projectId,
		    trackerId,
		    statusId,
		    priorityId,
		    authorId,
		    assignedToId,
		    parentId,
		    categoryId,
		    versionId,
		    subject,
		    description,
		    startDate,
		    dueDate,
		    doneRatio,
		    estimatedHours,
		    createdOn,
		    updatedOn,
		    closedOn
		)
		SELECT 
			c.value('(id/text())[1]', 'int'),
			c.value('(project//@id)[1]', 'int'),
			c.value('(tracker//@id)[1]', 'int'),
			c.value('(status//@id)[1]', 'int'),
			c.value('(priority//@id)[1]', 'int'),
			c.value('(author//@id)[1]', 'int'),
			c.value('(assigned_to//@id)[1]', 'int'),
			c.value('(parent//@id)[1]', 'int'),
			c.value('(category//@id)[1]', 'int'),
			c.value('(fixed_version//@id)[1]', 'int'),
			c.value('(subject/text())[1]', 'nvarchar(100)'),
			c.value('(description/text())[1]', 'nvarchar(max)'),
			c.value('(start_date/text())[1]', 'date'),
			c.value('(due_date/text())[1]', 'date'),
			c.value('(done_ratio/text())[1]', 'int'),
			c.value('(estimated_hours/text())[1]', 'decimal(9, 2)'),
			c.value('(created_on/text())[1]', 'datetimeoffset(0)'),
			c.value('(updated_on/text())[1]', 'datetimeoffset(0)'),
			c.value('(closed_on/text())[1]', 'datetimeoffset(0)')
		FROM @xml.nodes('/issues/issue') T(c)
		SET @total = @@ROWCOUNT
		PRINT STR(@total) + ' rows in xml (issues)'

		INSERT #customFields (
		    issueId,
		    customFieldId,
		    [value]
		)
		SELECT
			i.value('(id/text())[1]', 'int'),
			c.id,
			c.[value]
		FROM @xml.nodes('/issues/issue') T(i)
			CROSS APPLY (
				SELECT
					c.value('@id', 'int') id,
					LTRIM(RTRIM(c.value('(value/text())[1]', 'nvarchar(2000)'))) [value]
				FROM i.nodes('custom_fields/custom_field') T(c)
			) c
		WHERE c.[value] IS NOT NULL
		PRINT STR(@@ROWCOUNT) + ' rows in xml (custom fields)'

		INSERT #relations (
		    id,
		    issueId,
		    issueToId,
		    [type],
		    [delay]
		)
		SELECT -- no doubles allowed
			DISTINCT
			c.value('@id', 'int'),
			c.value('@issue_id', 'int'),
			c.value('@issue_to_id', 'int'),
			c.value('@relation_type', 'nvarchar(200)'),
			c.value('@delay', 'int')
		FROM @xml.nodes('/issues/issue/relations/relation') T(c)
		PRINT STR(@@ROWCOUNT) + ' rows in xml (relations)'
	END

	-- map
	BEGIN
		UPDATE d
		SET d._issueId = x.Id
		FROM #issues d
			JOIN dbo.Issue x ON x.Id = d.id
		WHERE d._issueId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows mapped (issues)'

		UPDATE d
		SET d._authorMemberId = x.Id
		FROM #issues d
			JOIN dbo.Member x ON x.RedmineId = d.authorId
		WHERE d._authorMemberId IS NULL
		PRINT STR(@@ROWCOUNT) + ' author members mapped (issues)'

		UPDATE d
		SET d._assignedMemberId = x.Id
		FROM #issues d
			JOIN dbo.Member x ON x.RedmineId = d.assignedToId
		WHERE d._assignedMemberId IS NULL
		PRINT STR(@@ROWCOUNT) + ' assigned members mapped (issues)'

		UPDATE d
		SET d._customFieldId = x.Id
		FROM #customFields d
			JOIN dbo.IssueCustomField x ON x.IssueId = d.issueId
				AND x.CustomFieldId = d.customFieldId
		WHERE d._customFieldId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows mapped (custom fields)'

		UPDATE d
		SET d._relationId = x.Id
		FROM #relations d
			JOIN dbo.IssueRelation x ON x.Id = d.id
		WHERE d._relationId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows mapped (relations)'
	END

	-- apply
	BEGIN
		UPDATE x
		SET x.ProjectId = d.projectId,
		    x.TrackerId = d.trackerId,
		    x.StatusId = d.statusId,
		    x.PriorityId = d.priorityId,
		    x.AuthorMemberId = d._authorMemberId,
		    x.AssignedToMemberId = d._assignedMemberId,
		    x.CategoryId = d.categoryId,
		    x.VersionId = d.versionId,
		    x.[Subject] = d.[subject],
		    x.[Description] = d.[description],
		    x.StartDate = d.startDate,
		    x.DueDate = d.dueDate,
		    x.DoneRatio = d.doneRatio,
		    x.EstimatedHours = d.estimatedHours,
		    x.RedmineCreated = d.createdOn,
		    x.RedmineUpdated = d.updatedOn,
		    x.RedmineClosed = d.closedOn,
			x.IsDeleted = 0,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #issues d
			JOIN dbo.Issue x ON x.Id = d._issueId
		WHERE x.ProjectId <> d.projectId
		    OR x.TrackerId <> d.trackerId
			OR x.StatusId <> d.statusId
		    OR x.PriorityId <> d.priorityId
		    OR x.[Subject] <> d.[subject]
		    OR x.RedmineCreated <> d.createdOn
			OR x.RedmineUpdated <> d.updatedOn
			OR x.IsDeleted = 1
			OR COALESCE(x.AuthorMemberId, 0) <> COALESCE(d._authorMemberId, 0)
		    OR COALESCE(x.AssignedToMemberId, 0) <> COALESCE(d._assignedMemberId, 0)
		    OR COALESCE(x.CategoryId, 0) <> COALESCE(d.categoryId, 0)
		    OR COALESCE(x.VersionId, 0) <> COALESCE(d.versionId, 0)
		    OR COALESCE(x.[Description], '') <> COALESCE(d.[description], '')
			OR COALESCE(x.DueDate, '19000101') <> COALESCE(d.DueDate, '19000101')
		    OR COALESCE(x.StartDate, '19000101') <> COALESCE(d.startDate, '19000101')
		    OR COALESCE(x.DueDate, '19000101') <> COALESCE(d.dueDate, '19000101')
		    OR COALESCE(x.DoneRatio, 0) <> COALESCE(d.doneRatio, 0)
		    OR COALESCE(x.EstimatedHours, 0) <> COALESCE(d.estimatedHours, 0)
		    OR COALESCE(x.RedmineClosed, '19000101') <> COALESCE(d.closedOn, '19000101')
		SET @updated = @@ROWCOUNT
		PRINT STR(@updated) + ' rows changed (issues)'

		INSERT dbo.Issue (
		    Id,
		    ProjectId,
		    TrackerId,
		    StatusId,
		    PriorityId,
		    AuthorMemberId,
		    AssignedToMemberId,
		    CategoryId,
		    VersionId,
		    Subject,
		    Description,
		    StartDate,
		    DueDate,
		    DoneRatio,
		    EstimatedHours,
		    RedmineCreated,
		    RedmineUpdated,
		    RedmineClosed,
		    LastHistoryDate,
		    IsDeleted,
		    Created,
		    Updated
		)
		SELECT
			d.id,
            d.projectId,
            d.trackerId,
            d.statusId,
            d.priorityId,
            d._authorMemberId,
            d._assignedMemberId,
            d.categoryId,
            d.versionId,
            d.subject,
            d.description,
            d.startDate,
            d.dueDate,
            d.doneRatio,
            d.estimatedHours,
            d.createdOn,
            d.updatedOn,
            d.closedOn,
			d.updatedOn,
			0,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #issues d
		WHERE d._issueId IS NULL
		SET @added = @@ROWCOUNT
		PRINT STR(@added) + ' rows added (issues)'

		-- insert fake parent issues
		INSERT dbo.Issue (
		    Id,
		    ProjectId,
		    TrackerId,
		    StatusId,
		    PriorityId,
			[Subject],
		    RedmineCreated,
			RedmineUpdated,
		    LastHistoryDate,
		    IsDeleted,
		    Created,
		    Updated
		)
		SELECT
			d.parentId,
			MIN(d.projectId),
			MIN(d.trackerId),
			@fakeStatusId,
			@fakePriorityId,
			'[Непринятая задача] Родительская для #' + CONVERT(NVARCHAR(50), MIN(d.Id)),
			MIN(d.createdOn),
			MIN(d.updatedOn),
			MIN(d.createdOn),
			0,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #issues d
		WHERE d.parentId IS NOT NULL
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Issue x
				WHERE x.Id = d.parentId
			)
		GROUP BY d.parentId
		SET @i = @@ROWCOUNT
		SET @added += @i
		PRINT STR(@i) + ' fake rows for parent issues added (issues)'

		-- insert fake related issues
		INSERT dbo.Issue (
		    Id,
		    ProjectId,
		    TrackerId,
		    StatusId,
		    PriorityId,
			[Subject],
		    RedmineCreated,
		    RedmineUpdated,
			LastHistoryDate,
		    IsDeleted,
		    Created,
		    Updated
		)
		SELECT
			d.issueToId,
			MIN(i.projectId),
			MIN(i.trackerId),
			@fakeStatusId,
			MIN(i.priorityId),
			'[Непринятая задача] Связанная для #' + CONVERT(NVARCHAR(50), MIN(i.Id)),
			MIN(i.createdOn),
			MIN(i.updatedOn),
			MIN(i.createdOn),
			0,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #relations d
			JOIN #issues i ON d.issueId = i.id
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.Issue x
				WHERE x.Id = d.issueToId
			)
		GROUP BY d.issueToId
		SET @i = @@ROWCOUNT
		SET @added += @i
		PRINT STR(@i) + ' fake rows for related issues added by issueToId (issues)'

		INSERT dbo.Issue (
		    Id,
		    ProjectId,
		    TrackerId,
		    StatusId,
		    PriorityId,
			[Subject],
		    RedmineCreated,
			RedmineUpdated,
		    LastHistoryDate,
		    IsDeleted,
		    Created,
		    Updated
		)
		SELECT
			d.issueId,
			MIN(i.projectId),
			MIN(i.trackerId),
			@fakeStatusId,
			MIN(i.priorityId),
			'[Непринятая задача] Связанная для #' + CONVERT(NVARCHAR(50), MIN(i.Id)),
			MIN(i.createdOn),
			MIN(i.updatedOn),
			MIN(i.createdOn),
			0,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #relations d
			JOIN #issues i ON d.issueToId = i.id
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.Issue x
				WHERE x.Id = d.issueId
			)
		GROUP BY d.issueId
		SET @i = @@ROWCOUNT
		SET @added += @i
		PRINT STR(@i) + ' fake rows for related issues added by issueId (issues)'

		-- map parent issues
		UPDATE x
		SET x.ParentId = d.parentId,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #issues d
			JOIN dbo.Issue x ON d.id = x.Id
		WHERE COALESCE(x.ParentId, 0) <> COALESCE(d.parentId, 0)

		-- store last received date
		UPDATE x
		SET x.LastReceivedDate = SYSDATETIMEOFFSET()
		FROM #issues d
			JOIN dbo.Issue x ON x.Id = d.id
		WHERE 1=1

		-- custom fields
		UPDATE x
		SET x.[Value] = NULL,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #issues i
			JOIN dbo.IssueCustomField x ON i.id = x.IssueId
		WHERE NOT EXISTS (
			SELECT 1
			FROM #customFields d
			WHERE d._customFieldId = x.Id
			)
		PRINT STR(@@ROWCOUNT) + ' rows reset (custom fields)'

		UPDATE x
		SET x.[Value] = d.[value],
			x.Updated = SYSDATETIMEOFFSET()
		FROM #customFields d
			JOIN dbo.IssueCustomField x ON d._customFieldId = x.Id
		WHERE COALESCE(x.[Value], '') <> COALESCE(d.[value], '')
		PRINT STR(@@ROWCOUNT) + ' rows changed (custom fields)'

		INSERT dbo.IssueCustomField (
		    IssueId,
		    CustomFieldId,
		    [Value],
		    Created,
		    Updated
		)
		SELECT
			d.issueId,
            d.customFieldId,
            d.[value],
            SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #customFields d
		WHERE d._customFieldId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows added (issues)'

		-- issue relations
		DELETE x
		FROM #issues i
			JOIN dbo.IssueRelation x ON i.id = x.IssueId
		WHERE NOT EXISTS (
			SELECT 1
			FROM #relations d
			WHERE d._relationId = x.Id
			)
		PRINT STR(@@ROWCOUNT) + ' rows reset by issueId (custom fields)'

		DELETE x
		FROM #issues i
			JOIN dbo.IssueRelation x ON i.id = x.IssueToId
		WHERE NOT EXISTS (
			SELECT 1
			FROM #relations d
			WHERE d._relationId = x.Id
			)
		PRINT STR(@@ROWCOUNT) + ' rows reset by issueToId (custom fields)'

		UPDATE x
		SET x.IssueId = d.issueId,
			x.IssueToId = d.issueToId,
			x.[Type] = d.[type],
			x.[Delay] = d.[delay],
			x.Updated = SYSDATETIMEOFFSET()
		FROM #relations d
			JOIN dbo.IssueRelation x ON x.id = d._relationId
		WHERE x.IssueId <> d.issueId
			OR x.IssueToId <> d.issueToId
			OR x.[Type] <> d.[type]
			OR COALESCE(x.[Delay], 0) <> COALESCE(d.[delay], 0)
		PRINT STR(@@ROWCOUNT) + ' rows changed (relations)'

		INSERT dbo.IssueRelation (
		    Id,
		    IssueId,
		    IssueToId,
		    [Type],
		    [Delay],
		    Created,
		    Updated
		)
		SELECT
			d.id,
            d.issueId,
            d.issueToId,
            d.[type],
            d.[delay],
            SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #relations d
		WHERE d._relationId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows added (relations)'
    END

	DROP TABLE #issues
	DROP TABLE #customFields
	DROP TABLE #relations
END
GO
