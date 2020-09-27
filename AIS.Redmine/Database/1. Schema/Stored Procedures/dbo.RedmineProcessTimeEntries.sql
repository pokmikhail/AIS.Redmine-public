SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RedmineProcessTimeEntries]
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
		CREATE TABLE #timeEntries (
			id INT NOT NULL,
			projectId INT NOT NULL,
			issueId INT NOT NULL,
			memberId INT NOT NULL,
			[date] DATE NOT NULL,
			activityId INT NOT NULL,
			[hours] DECIMAL(9, 2) NOT NULL,
			comments NVARCHAR(2000) COLLATE DATABASE_DEFAULT,
			createdOn DATETIMEOFFSET(0) NOT NULL,
			updatedOn DATETIMEOFFSET(0) NOT NULL,
		
			_timeEntryId INT,
			_memberId INT
		)
	END

	-- FILL
	BEGIN
		INSERT #timeEntries (
		    id,
		    projectId,
		    issueId,
		    memberId,
			[date],
		    activityId,
		    [hours],
		    comments,
		    createdOn,
		    updatedOn
		)
		SELECT 
			c.value('(id/text())[1]', 'int'),
			c.value('(project//@id)[1]', 'int'),
			c.value('(issue//@id)[1]', 'int'),
			c.value('(user//@id)[1]', 'int'),
			c.value('(spent_on/text())[1]', 'date'),
			c.value('(activity//@id)[1]', 'int'),
			c.value('(hours/text())[1]', 'decimal(9, 2)'),
			c.value('(comments/text())[1]', 'nvarchar(2000)'),
			c.value('(created_on/text())[1]', 'datetimeoffset(0)'),
			c.value('(updated_on/text())[1]', 'datetimeoffset(0)')
		FROM @xml.nodes('/time_entries/time_entry') T(c)
		SET @total = @@ROWCOUNT
		PRINT STR(@total) + ' rows in xml'
	END

	-- map
	BEGIN
		UPDATE d
		SET d._timeEntryId = x.Id
		FROM #timeEntries d
			JOIN dbo.TimeEntry x ON x.Id = d.id
		WHERE d._timeEntryId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows mapped'

		UPDATE d
		SET d._memberId = x.Id
		FROM #timeEntries d
			JOIN dbo.Member x ON x.RedmineId = d.memberId
		WHERE d._memberId IS NULL
	END

	-- apply
	BEGIN
		UPDATE x
		SET x.ProjectId = d.projectId,
			x.IssueId = d.issueId,
			x.MemberId = d._memberId,
			x.[Date] = d.[date],
			x.TypeId = d.activityId,
			x.[Hours] = d.[hours],
			x.Comments = d.comments,
			x.RedmineUpdated = d.updatedOn,
			x.IsDeleted = 0,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #timeEntries d
			JOIN dbo.TimeEntry x ON x.Id = d._timeEntryId
		WHERE x.ProjectId <> d.projectId
			OR x.IssueId <> d.IssueId
			OR x.MemberId <> d._memberId
			OR x.[Date] <> d.[date]
			OR x.TypeId <> d.activityId
			OR x.[Hours] <> d.[hours]
			OR x.RedmineUpdated <> d.updatedOn
			OR x.IsDeleted = 1
			OR COALESCE(x.Comments, '') <> COALESCE(d.comments, '')
		SET @updated = @@ROWCOUNT
		PRINT STR(@updated) + ' rows changed'

		INSERT dbo.TimeEntry (
		    Id,
		    ProjectId,
		    IssueId,
		    MemberId,
		    [Date],
		    TypeId,
		    [Hours],
		    Comments,
		    RedmineCreated,
		    RedmineUpdated,
		    IsDeleted,
		    Created,
		    Updated
		)
		SELECT
			d.id,
            d.projectId,
            d.issueId,
            d._memberId,
            d.[date],
            d.activityId,
            d.[hours],
            d.comments,
            d.createdOn,
            d.updatedOn,
			0,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #timeEntries d
		WHERE d._timeEntryId IS NULL
		SET @added = @@ROWCOUNT
		PRINT STR(@added) + ' rows added'

		-- store last received date
		UPDATE x
		SET x.LastReceivedDate = SYSDATETIMEOFFSET()
		FROM #timeEntries d
			JOIN dbo.TimeEntry x ON x.Id = d.Id
		WHERE 1=1
    END

	DROP TABLE #timeEntries 
END
GO
