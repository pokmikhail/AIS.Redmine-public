CREATE TABLE [dbo].[Issue]
(
[Id] [int] NOT NULL,
[ProjectId] [int] NOT NULL,
[TrackerId] [int] NOT NULL,
[StatusId] [int] NOT NULL,
[PriorityId] [int] NOT NULL,
[AuthorMemberId] [int] NULL,
[AssignedToMemberId] [int] NULL,
[ParentId] [int] NULL,
[CategoryId] [int] NULL,
[VersionId] [int] NULL,
[Subject] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Description] [nvarchar] (max) COLLATE Cyrillic_General_CI_AI NULL,
[StartDate] [date] NULL,
[DueDate] [date] NULL,
[DoneRatio] [int] NULL,
[EstimatedHours] [decimal] (9, 2) NULL,
[TotalEstimatedHours] [decimal] (9, 2) NULL,
[SpentHours] [decimal] (9, 2) NULL,
[TotalSpentHours] [decimal] (9, 2) NULL,
[RedmineCreated] [datetimeoffset] (0) NOT NULL,
[RedmineUpdated] [datetimeoffset] (0) NOT NULL,
[RedmineClosed] [datetimeoffset] (0) NULL,
[LastHistoryDate] [datetimeoffset] (0) NOT NULL,
[LastReceivedDate] [datetimeoffset] (0) NULL,
[IsDeleted] [bit] NOT NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [PK_Issue] PRIMARY KEY CLUSTERED  ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_Issue_Parent] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[Issue] ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_IssueCategory] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[IssueCategory] ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_IssuePriority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[IssuePriority] ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_IssueStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[IssueStatus] ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_IssueTracker] FOREIGN KEY ([TrackerId]) REFERENCES [dbo].[IssueTracker] ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_IssueVersion] FOREIGN KEY ([VersionId]) REFERENCES [dbo].[IssueVersion] ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_Member_AsssignedTo] FOREIGN KEY ([AssignedToMemberId]) REFERENCES [dbo].[Member] ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_Member_Author] FOREIGN KEY ([AuthorMemberId]) REFERENCES [dbo].[Member] ([Id])
GO
ALTER TABLE [dbo].[Issue] ADD CONSTRAINT [FK_Issue_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Задачи', 'SCHEMA', N'dbo', 'TABLE', N'Issue', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Назначена', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'AssignedToMemberId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Автор', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'AuthorMemberId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Категория', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'CategoryId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Описание', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'Description'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Процент готовности', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'DoneRatio'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата завершения', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'DueDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Оценка времени, ч', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'EstimatedHours'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Удалена?ы', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'IsDeleted'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Последнее изменение по журналу изменений', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'LastHistoryDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата последнего приёма данных из Redmine', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'LastReceivedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Родительская задача', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'ParentId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Приоритет', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'PriorityId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Проект', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'ProjectId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата закрытия в Редмайне', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'RedmineClosed'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата создания в Редмайне', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'RedmineCreated'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата обновления Дата создания в Редмайне', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'RedmineUpdated'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Затрачено времени, ч', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'SpentHours'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата начала', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'StartDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Статус', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'StatusId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Тема', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'Subject'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Оценка времени, включая подзадачи, ч', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'TotalEstimatedHours'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Затрачено времени, включая подзадачи, ч', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'TotalSpentHours'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Трекер', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'TrackerId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Версия', 'SCHEMA', N'dbo', 'TABLE', N'Issue', 'COLUMN', N'VersionId'
GO
