CREATE TABLE [dbo].[IssueVersion]
(
[Id] [int] NOT NULL,
[ProjectId] [int] NOT NULL,
[Name] [nvarchar] (500) COLLATE Cyrillic_General_CI_AI NOT NULL,
[DueDate] [date] NULL,
[IsClosed] [bit] NOT NULL,
[IsDeleted] [bit] NOT NULL,
[RedmineCreated] [datetimeoffset] (0) NOT NULL,
[RedmineUpdated] [datetimeoffset] (0) NOT NULL,
[LastReceivedDate] [datetimeoffset] (0) NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueVersion] ADD CONSTRAINT [PK_IssueVersion] PRIMARY KEY CLUSTERED  ([Id])
GO
ALTER TABLE [dbo].[IssueVersion] ADD CONSTRAINT [FK_IssueVersion_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Версии', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата выхода', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', 'COLUMN', N'DueDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Версия закрыта?', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', 'COLUMN', N'IsClosed'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Запись удалена?', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', 'COLUMN', N'IsDeleted'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата последнего приёма данных из Redmine', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', 'COLUMN', N'LastReceivedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Проект', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', 'COLUMN', N'ProjectId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата создания в Редмайн', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', 'COLUMN', N'RedmineCreated'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата обновления в Редмайн', 'SCHEMA', N'dbo', 'TABLE', N'IssueVersion', 'COLUMN', N'RedmineUpdated'
GO
