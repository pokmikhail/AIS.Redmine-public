CREATE TABLE [dbo].[IssueTracker]
(
[Id] [int] NOT NULL,
[Name] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueTracker] ADD CONSTRAINT [PK_IssueTracker] PRIMARY KEY CLUSTERED  ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Трекеры задач', 'SCHEMA', N'dbo', 'TABLE', N'IssueTracker', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование', 'SCHEMA', N'dbo', 'TABLE', N'IssueTracker', 'COLUMN', N'Name'
GO
