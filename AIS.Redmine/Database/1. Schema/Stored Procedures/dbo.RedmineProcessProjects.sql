SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RedmineProcessProjects]
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
		CREATE TABLE #projects (
			id INT,
			parentId INT,
			[code] NVARCHAR(100) COLLATE DATABASE_DEFAULT,
			[name] NVARCHAR(100) COLLATE DATABASE_DEFAULT,
			--[description] NVARCHAR(1000) COLLATE DATABASE_DEFAULT,
			instanceCode NVARCHAR(100) COLLATE DATABASE_DEFAULT,
			instanceName NVARCHAR(100) COLLATE DATABASE_DEFAULT,
			contractNumber NVARCHAR(100) COLLATE DATABASE_DEFAULT,
			contractExpirationDate DATE,
			contractHours INT,
			certificateExpirationDate DATE,
			createdOn DATETIMEOFFSET(0),
			--updatedOn DATETIMEOFFSET(0),
		
			_projectId INT
		)

		CREATE TABLE #categories (
			id INT,
			projectId INT,
			[name] NVARCHAR(100) COLLATE DATABASE_DEFAULT,
		
			_categoryId INT
		)
	END

	-- FILL
	BEGIN
		INSERT #projects (
			id,
			parentId,
			code,
			name,
			--description,
			instanceCode,
			instanceName,
			contractNumber,
			contractExpirationDate,
			contractHours,
			certificateExpirationDate,
			createdOn
			--updatedOn
		)
		SELECT 
			c.value('id[1]', 'int'),
			c.value('(parent/@id)[1]', 'int'),
			c.value('identifier[1]', 'nvarchar(100)'),
			c.value('name[1]', 'nvarchar(100)'),
			--NULLIF(c.value('description[1]', 'nvarchar(1000)'), ''),
			NULLIF(c.value('custom_fields[1]/custom_field[@id="26"][1]', 'nvarchar(100)'), '') code,
			NULLIF(c.value('custom_fields[1]/custom_field[@id="29"][1]', 'nvarchar(100)'), '') [name],
			NULLIF(c.value('custom_fields[1]/custom_field[@id="30"][1]', 'nvarchar(100)'), '') c_number,
			NULLIF(c.value('custom_fields[1]/custom_field[@id="28"][1]', 'date'), '19000101') c_expire,
			NULLIF(c.value('custom_fields[1]/custom_field[@id="25"][1]', 'int'), 0) c_hours,
			NULLIF(c.value('custom_fields[1]/custom_field[@id="27"][1]', 'date'), '19000101') cert_expire,
			c.value('created_on[1]', 'datetimeoffset(0)')
			--c.value('updated_on[1]', 'datetimeoffset(0)')
		FROM @xml.nodes('/projects/project') T(c)
		SET @total = @@ROWCOUNT
		PRINT STR(@total) + ' rows in xml'

		INSERT #categories (
			id,
			projectId,
			[name]
		)
		SELECT 
			p.value('@id[1]', 'int'),
			p.value('../../id[1]', 'int'),
			p.value('@name[1]', 'nvarchar(100)')
		FROM @xml.nodes('/projects/project/issue_categories/issue_category') T(p)
		PRINT STR(@@ROWCOUNT) + ' categories in xml'
	END

	-- map
	BEGIN
		UPDATE d
		SET d._projectId = x.Id
		FROM #projects d
			JOIN dbo.Project x ON x.Code = d.code
		WHERE d._projectId IS NULL
		PRINT STR(@@ROWCOUNT) + ' rows mapped'

		UPDATE d
		SET d._categoryId = x.Id
		FROM #categories d
			JOIN dbo.IssueCategory x ON x.Id = d.id
		WHERE d._categoryId IS NULL
		PRINT STR(@@ROWCOUNT) + ' categories mapped'
	END

	-- apply
	BEGIN
		UPDATE x
		SET x.RedmineName = d.[name],
			x.InstanceCode = d.instanceCode,
			x.InstanceName = d.instanceName,
			x.ContractNumber = d.contractNumber,
			x.ContractExpirationDate = d.contractExpirationDate,
			x.ContractHoursPerMonth = d.contractHours,
			x.GisCertificateExpirationDate = d.certificateExpirationDate,
			x.RedmineCreated = d.createdOn,
			x.IsDeleted = 0,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #projects d
			JOIN dbo.Project x ON d._projectId = x.Id
		WHERE x.RedmineName <> d.[name]
			OR x.RedmineCreated <> d.createdOn
			OR ISNULL(x.InstanceCode, '') <> ISNULL(d.instanceCode, '')
			OR ISNULL(x.InstanceName, '') <> ISNULL(d.instanceName, '')
			OR ISNULL(x.ContractNumber, '') <> ISNULL(d.contractNumber, '')
			OR ISNULL(x.ContractExpirationDate, '19000101') <> ISNULL(d.contractExpirationDate, '19000101')
			OR ISNULL(x.ContractHoursPerMonth, 0) <> ISNULL(d.contractHours, 0)
			OR ISNULL(x.GisCertificateExpirationDate, '19000101') <> ISNULL(d.certificateExpirationDate, '19000101')
			OR x.IsDeleted = 1
		SET @updated = @@ROWCOUNT
		PRINT STR(@updated) + ' rows changed'

		INSERT dbo.Project (
		    Id,
		    Code,
		    [Name],
		    RedmineName,
		    HasRevisions,
			HasVersions,
		    InstanceCode,
		    InstanceName,
		    ContractNumber,
		    ContractExpirationDate,
		    ContractHoursPerMonth,
		    GisCertificateExpirationDate,
		    IsDeleted,
		    RedmineCreated,
		    Created,
		    Updated
		)
		SELECT
			d.Id,
			d.code,
			d.[name],
			d.[name],
			0,
			0,
			d.instanceCode,
			d.instanceName,
			d.contractNumber,
			d.contractExpirationDate,
			d.contractHours,
			d.certificateExpirationDate,
			0,
			d.createdOn,
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #projects d
		WHERE d._projectId IS NULL
		SET @added = @@ROWCOUNT
		PRINT STR(@added) + ' rows added'

		-- second pass, update parents
		UPDATE x
		SET x.ParentId = d.parentId,
			x.Updated = SYSDATETIMEOFFSET()
		FROM #projects d
			JOIN dbo.Project x ON x.Id = d.id
		WHERE ISNULL(x.ParentId, 0) <> ISNULL(d.parentId, 0)

		UPDATE x
		SET x.ProjectId = d.projectId,
			x.RedmineName = d.[name],
			x.Updated = SYSDATETIMEOFFSET()
		FROM #categories d
			JOIN dbo.IssueCategory x ON x.Id = d._categoryId
		WHERE x.RedmineName <> d.[name]
			OR x.ProjectId <> d.projectId
		PRINT STR(@@ROWCOUNT) + ' categories changed'

		INSERT dbo.IssueCategory (
		    Id,
		    ProjectId,
		    Name,
		    RedmineName,
		    Created,
		    Updated
		)
		SELECT
			d.Id,
			d.projectId,
			d.[name],
			d.[name],
			SYSDATETIMEOFFSET(),
			SYSDATETIMEOFFSET()
		FROM #categories d
		WHERE d._categoryId IS NULL
		PRINT STR(@@ROWCOUNT) + ' categories added'

		-- store last received date
		UPDATE x
		SET x.LastReceivedDate = SYSDATETIMEOFFSET()
		FROM #projects d
			JOIN dbo.Project x ON x.Code = d.code
		WHERE 1=1
    END

	DROP TABLE #projects 
	DROP TABLE #categories
END
GO
