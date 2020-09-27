SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RedmineProcessIssueDetails]
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
		@issueId INT

	-- init
	BEGIN
		-- we need only 3 fields for the issue
		CREATE TABLE #issue (
			id INT PRIMARY KEY,
			totalEstimatedHours DECIMAL(9, 2),
			spentHours DECIMAL(9, 2),
			totalSpentHours decimal(9, 2),
			lastHistoryDate DATETIMEOFFSET(0) NOT NULL
		)

		CREATE TABLE #journals (
			id INT NOT NULL PRIMARY KEY,
			memberId INT NOT NULL,
			notes NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
			createdOn DATETIMEOFFSET(0) NOT NULL,
			isPrivate BIT NOT NULL,

			_journalId INT,
			_memberId INT
		)

		CREATE TABLE #journalDetails (
			journalId INT,
			propertyType NVARCHAR(100) COLLATE DATABASE_DEFAULT,
			propertyName NVARCHAR(200) COLLATE DATABASE_DEFAULT,
			oldValue NVARCHAR(500) COLLATE DATABASE_DEFAULT,
			newValue NVARCHAR(500) COLLATE DATABASE_DEFAULT
		)

		CREATE TABLE #changesets (
			revision NVARCHAR(100) COLLATE DATABASE_DEFAULT NOT NULL,
			memberId INT,
			comment NVARCHAR(2000) COLLATE DATABASE_DEFAULT,
			committedOn DATETIMEOFFSET(0) NOT NULL,

			_issueRevisionId INT,
			_memberId INT
		)
	END

	-- fill
	BEGIN
		INSERT #issue (
		    id,
		    totalEstimatedHours,
		    spentHours,
		    totalSpentHours,
			lastHistoryDate
		)
		SELECT 
			c.value('(id/text())[1]', 'int'),
			-- you can't just convert an empty string to a decimal :(
			c.value('(total_estimated_hours/text())[1]', 'decimal(9, 2)'),
			c.value('(spent_hours/text())[1]', 'decimal(9, 2)'),
			c.value('(total_spent_hours/text())[1]', 'decimal(9, 2)'),
			c.value('(updated_on/text())[1]', 'datetimeoffset(0)')
		FROM @xml.nodes('/issue') T(c);
		SET @total = @@ROWCOUNT
		PRINT STR(@total) + ' rows in xml (issue)'

		SELECT @issueId = d.Id
		FROM #issue d

		INSERT #journals (
		    id,
		    memberId,
		    notes,
		    createdOn,
		    isPrivate
		)
		SELECT
			c.value('@id', 'int'),
			c.value('(user//@id)[1]', 'int'),
			LTRIM(RTRIM(c.value('(notes/text())[1]', 'nvarchar(2000)'))),
			c.value('(created_on/text())[1]', 'datetimeoffset(0)'),
			c.value('(private_notes/text())[1]', 'bit')
		FROM @xml.nodes('/issue/journals/journal') T(c)
		PRINT STR(@@ROWCOUNT) + ' rows in xml (journals)'

		UPDATE i
		SET i.lastHistoryDate = j.[max]
		FROM #issue i
			CROSS APPLY (
				SELECT MAX(createdOn) [max]
				FROM #journals
				) j
		WHERE j.[max] > i.lastHistoryDate

		INSERT #journalDetails (
		    journalId,
			propertyType,
		    propertyName,
		    oldValue,
		    newValue
		)
		SELECT
			j.value('@id', 'int'),
			c.property,
            c.[name],
            c.oldValue,
            c.newValue
		FROM @xml.nodes('/issue/journals/journal') T(j)
			CROSS APPLY (
				SELECT
					c.value('@property', 'nvarchar(100)') property,
					c.value('@name', 'nvarchar(200)') [name],
					c.value('(old_value/text())[1]', 'nvarchar(500)') oldValue,
					c.value('(new_value/text())[1]', 'nvarchar(500)') newValue
				FROM j.nodes('details/detail') T(c)
			) c
		PRINT STR(@@ROWCOUNT) + ' rows in xml (journal details)'

		INSERT #changesets (
		    revision,
		    memberId,
		    comment,
		    committedOn
		)
		SELECT
			c.value('@revision', 'nvarchar(100)'),
			c.value('(user//@id)[1]', 'int'),
			c.value('(comments/text())[1]', 'nvarchar(500)'),
			c.value('(committed_on/text())[1]', 'datetimeoffset(0)')
		FROM @xml.nodes('/issue/changesets/changeset') T(c)
		PRINT STR(@@ROWCOUNT) + ' rows in xml (changesets)'

		UPDATE i
		SET i.lastHistoryDate = j.[max]
		FROM #issue i
			CROSS APPLY (
				SELECT MAX(committedOn) [max]
				FROM #changesets
				) j
		WHERE j.[max] > i.lastHistoryDate
	END

	-- map
	BEGIN
		UPDATE d
		SET d._journalId = x.Id
		FROM #journals d
			JOIN dbo.IssueJournal x ON d.id = x.id
		WHERE d._journalId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows mapped (journals)'

		UPDATE d
		SET d._memberId = x.Id
		FROM #journals d
			JOIN dbo.Member x ON d.memberId = x.RedmineId
		WHERE d._memberId IS NULL
		PRINT STR(@@ROWCOUNT) + ' members mapped (journals)'

		UPDATE d
		SET d._memberId = x.Id
		FROM #changesets d
			JOIN dbo.Member x ON d.memberId= x.RedmineId
		WHERE d._memberId IS NULL
		PRINT STR(@@ROWCOUNT) + ' members mapped (changesets)'

		UPDATE d
		SET d._issueRevisionId = x.Id
		FROM #changesets d
			JOIN dbo.IssueRevision x ON x.IssueId = @issueId
				AND x.Revision = d.revision
		WHERE d._issueRevisionId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows mapped (changesets)'
	END

	-- apply
	BEGIN
		UPDATE x
		SET x.TotalEstimatedHours = d.totalEstimatedHours,
			x.SpentHours = d.spentHours,
			x.TotalSpentHours = d.totalSpentHours,
			x.LastHistoryDate = CASE
				WHEN x.LastHistoryDate < d.lastHistoryDate
				THEN d.lastHistoryDate
				ELSE x.LastHistoryDate
				END,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #issue d
			JOIN dbo.Issue x ON x.Id = d.id
		WHERE x.LastHistoryDate < d.lastHistoryDate
			OR COALESCE(x.TotalEstimatedHours, 0) <> COALESCE(d.totalEstimatedHours, 0)
		    OR COALESCE(x.SpentHours, 0) <> COALESCE(d.spentHours, 0)
		    OR COALESCE(x.TotalSpentHours, 0) <> COALESCE(d.totalSpentHours, 0)
		SET @updated = @@ROWCOUNT
		PRINT STR(@updated) + ' rows changed (issue)'

		-- store last received date
		UPDATE x
		SET x.LastReceivedDate = SYSDATETIMEOFFSET()
		FROM dbo.Issue x
		WHERE x.Id = @issueId

		-- journals
		UPDATE x
		SET x.IsDeleted = 1,
			x.Updated = SYSDATETIMEOFFSET()
		FROM dbo.IssueJournal x
		WHERE x.IssueId = @issueId
			AND x.IsDeleted = 0
			AND NOT EXISTS (
				SELECT 1
				FROM #journals d
				WHERE d.id = x.Id
			)
		PRINT STR(@@ROWCOUNT) + ' rows reset (journals)'

		UPDATE x
		SET x.MemberId = d._memberId,
			x.Comment = d.notes,
			x.IsPrivate = d.isPrivate,
			x.IsDeleted = 0,
			x.RedmineCreated = d.createdOn,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #journals d
			JOIN dbo.IssueJournal x ON d._journalId = x.Id
		WHERE x.MemberId <> d._memberId
			OR x.IsPrivate <> d.isPrivate
			OR x.RedmineCreated <> d.createdOn
			OR x.IsDeleted = 1
			OR COALESCE(x.Comment, '') <> COALESCE(d.notes, '')
		PRINT STR(@@ROWCOUNT) + ' rows changed (journals)'

		INSERT dbo.IssueJournal (
		    Id,
		    IssueId,
		    MemberId,
		    Comment,
		    IsPrivate,
		    IsDeleted,
		    RedmineCreated,
		    Created,
		    Updated
		)
		SELECT
			d.id,
			@issueId,
            d._memberId,
            d.notes,
			d.isPrivate,
			0,
			d.createdOn,
            SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #journals d
		WHERE d._journalId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows added (journals)'

		INSERT dbo.IssueJournalDetails (
		    IssueJournalId,
		    [Type],
		    [Name],
		    OldValue,
		    NewValue,
		    Created,
		    Updated
		)
		SELECT
			d.journalId,
            d.propertyType,
            d.propertyName,
            d.oldValue,
            d.newValue,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #journalDetails d
		WHERE NOT EXISTS (
				SELECT 1
				FROM #journals x
				WHERE x._journalId = d.journalId
			)
		PRINT STR(@@ROWCOUNT) + ' rows added (journal details)'

		-- changesets
		DELETE x
		FROM dbo.IssueRevision x
		WHERE x.IssueId = @issueId
			AND NOT EXISTS (
				SELECT 1
				FROM #changesets d
				WHERE d._issueRevisionId = x.Id
			)
		PRINT STR(@@ROWCOUNT) + ' rows deleted (changesets)'

		UPDATE x
		SET x.MemberId = d._memberId,
			x.Comment = d.comment,
			x.RedmineCommitted = d.committedOn,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #changesets d
			JOIN dbo.IssueRevision x ON x.id = d._issueRevisionId
		WHERE x.RedmineCommitted <> d.committedOn
			OR COALESCE(x.MemberId, 0) <> COALESCE(d._memberId, 0)
			OR COALESCE(x.Comment, '') <> COALESCE(d.Comment, '')
		PRINT STR(@@ROWCOUNT) + ' rows changed (changesets)'

		INSERT dbo.IssueRevision (
		    IssueId,
		    Revision,
		    MemberId,
		    Comment,
		    RedmineCommitted,
		    Created,
		    Updated
		)
		SELECT
			@issueId,
            d.revision,
            d._memberId,
            d.comment,
            d.committedOn,
            SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #changesets d
		WHERE d._issueRevisionId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows added (changesets)'
    END

	DROP TABLE #issue
	DROP TABLE #journals
	DROP TABLE #journalDetails
	DROP TABLE #changesets
END
GO
