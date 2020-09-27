CREATE TABLE [dbo].[IssueCategory]
(
[Id] [int] NOT NULL,
[ProjectId] [int] NOT NULL,
[Name] [nvarchar] (100) COLLATE Cyrillic_General_CI_AI NOT NULL,
[RedmineName] [nvarchar] (100) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueCategory] ADD CONSTRAINT [PK_IssueCategory] PRIMARY KEY CLUSTERED  ([Id])
GO
ALTER TABLE [dbo].[IssueCategory] ADD CONSTRAINT [FK_IssueCategory_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Категории задач', 'SCHEMA', N'dbo', 'TABLE', N'IssueCategory', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование', 'SCHEMA', N'dbo', 'TABLE', N'IssueCategory', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Проект', 'SCHEMA', N'dbo', 'TABLE', N'IssueCategory', 'COLUMN', N'ProjectId'
GO
