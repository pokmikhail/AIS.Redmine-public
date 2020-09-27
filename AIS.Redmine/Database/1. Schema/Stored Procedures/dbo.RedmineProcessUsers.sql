SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RedmineProcessUsers]
	@xml XML,
	@isActive BIT,
	@total INT OUTPUT,
	@added INT OUTPUT,
	@updated INT OUTPUT,
	@deleted INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE
		@i INT,
		@isDeleted BIT

	SELECT
		@isDeleted = 1 - COALESCE(@isActive, 0)

	CREATE TABLE #users (
		id INT,
		[login] NVARCHAR(100) COLLATE DATABASE_DEFAULT,
		--firstName NVARCHAR(100) COLLATE DATABASE_DEFAULT,
		--lastName NVARCHAR(100) COLLATE DATABASE_DEFAULT,
		composedName NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		--mail NVARCHAR(100) COLLATE DATABASE_DEFAULT,
		createdOn DATETIMEOFFSET(0),
		--lastLoginOn DATETIMEOFFSET(0),

		_userId INT
	)

	INSERT #users (
	    id,
	    login,
	    --firstName,
	    --lastName,
		composedName,
	    --mail,
	    createdOn
	    --lastLoginOn
	)
	SELECT
		c.value('id[1]', 'int'),
		c.value('login[1]', 'nvarchar(100)'),
		--c.value('firstname[1]', 'nvarchar(100)'),
		--c.value('lastname[1]', 'nvarchar(100)'),
		c.value('lastname[1]', 'nvarchar(100)') + ' ' + c.value('firstname[1]', 'nvarchar(100)'),
		--c.value('mail[1]', 'nvarchar(100)'),
		c.value('created_on[1]', 'datetimeoffset(0)')
		--c.value('last_login_on[1]', 'datetimeoffset(0)')
	FROM @xml.nodes('/users/user') T(c)
	SET @total = @@ROWCOUNT
	PRINT STR(@total) + ' rows in xml'

	-- map
	BEGIN
		SET @i = 0
		
		UPDATE d
		SET d._userId = x.Id
		FROM #users d
			JOIN dbo.Member x ON x.RedmineId = d.id
		WHERE d._userId IS NULL
		SET @i += @@ROWCOUNT

		UPDATE d
		SET d._userId = x.Id
		FROM #users d
			JOIN dbo.Member x ON x.RedmineLogin = d.[login]
		WHERE d._userId IS NULL
			AND x.RedmineId IS NULL
		SET @i += @@ROWCOUNT

		PRINT STR(@i) + ' rows mapped'
	END

	-- apply
	BEGIN
		UPDATE x
		SET x.RedmineId = d.id,
			x.[Name] = d.composedName,
			x.RedmineLogin = d.[login],
			x.IsDeleted = @isDeleted,
			x.RedmineCreated = d.createdOn,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #users d
			JOIN dbo.Member x ON x.Id = d._userId
		WHERE x.RedmineId IS NULL
			OR x.RedmineLogin <> d.[login]
			OR x.[Name] <> d.composedName
			OR x.IsDeleted <> @isDeleted
			OR x.RedmineCreated <> d.createdOn
		SET @updated = @@ROWCOUNT
		PRINT STR(@updated) + ' rows changed'

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
			d.id,
			d.composedName,
			d.composedName,
			d.[login],
			@isDeleted,
			d.createdOn,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #users d
		WHERE d._userId IS NULL
		SET @added = @@ROWCOUNT
		PRINT STR(@added) + ' rows added'

		-- store last received date
		UPDATE x
		SET x.LastReceivedDate = SYSDATETIMEOFFSET()
		FROM #users d
			JOIN dbo.Member x ON x.RedmineId = d.id
		WHERE 1=1
	END

	DROP TABLE #users
END
GO
