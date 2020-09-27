CREATE TABLE [dbo].[TimeEntry]
(
[Id] [int] NOT NULL,
[ProjectId] [int] NOT NULL,
[IssueId] [int] NOT NULL,
[MemberId] [int] NOT NULL,
[Date] [date] NOT NULL,
[TypeId] [int] NOT NULL,
[Hours] [decimal] (9, 2) NOT NULL,
[Comments] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NULL,
[RedmineCreated] [datetimeoffset] (0) NOT NULL,
[RedmineUpdated] [datetimeoffset] (0) NOT NULL,
[LastReceivedDate] [datetimeoffset] (0) NULL,
[IsDeleted] [bit] NOT NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[TimeEntry] ADD CONSTRAINT [PK_TimeEntry] PRIMARY KEY CLUSTERED  ([Id])
GO
ALTER TABLE [dbo].[TimeEntry] ADD CONSTRAINT [FK_TimeEntry_Issue] FOREIGN KEY ([IssueId]) REFERENCES [dbo].[Issue] ([Id])
GO
ALTER TABLE [dbo].[TimeEntry] ADD CONSTRAINT [FK_TimeEntry_Member] FOREIGN KEY ([MemberId]) REFERENCES [dbo].[Member] ([Id])
GO
ALTER TABLE [dbo].[TimeEntry] ADD CONSTRAINT [FK_TimeEntry_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([Id])
GO
ALTER TABLE [dbo].[TimeEntry] ADD CONSTRAINT [FK_TimeEntry_TimeEntryType] FOREIGN KEY ([TypeId]) REFERENCES [dbo].[TimeEntryType] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Трудозатраты', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Комметарий', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'Comments'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'Date'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Часы', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'Hours'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Удалено?', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'IsDeleted'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Задача', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'IssueId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата последнего приёма данных из Redmine', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'LastReceivedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Пользователь', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'MemberId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Проект', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'ProjectId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата создания в Redmine', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'RedmineCreated'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата обновления в Redmine', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'RedmineUpdated'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Тип', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntry', 'COLUMN', N'TypeId'
GO
