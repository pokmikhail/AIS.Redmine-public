CREATE TABLE [dbo].[IssueJournal]
(
[Id] [int] NOT NULL,
[IssueId] [int] NOT NULL,
[MemberId] [int] NOT NULL,
[Comment] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NULL,
[IsPrivate] [bit] NOT NULL,
[IsDeleted] [bit] NOT NULL,
[RedmineCreated] [datetimeoffset] (0) NOT NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueJournal] ADD CONSTRAINT [PK_IssueJournal] PRIMARY KEY CLUSTERED  ([Id])
GO
CREATE NONCLUSTERED INDEX [IX_IssueJournal_isssue_deleted] ON [dbo].[IssueJournal] ([IssueId], [IsDeleted])
GO
ALTER TABLE [dbo].[IssueJournal] ADD CONSTRAINT [FK_IssueJournal_Issue] FOREIGN KEY ([IssueId]) REFERENCES [dbo].[Issue] ([Id])
GO
ALTER TABLE [dbo].[IssueJournal] ADD CONSTRAINT [FK_IssueJournal_Member] FOREIGN KEY ([MemberId]) REFERENCES [dbo].[Member] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'История изменений задачи', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournal', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Примечание', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournal', 'COLUMN', N'Comment'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Удалена?', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournal', 'COLUMN', N'IsDeleted'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Приватный комментарий?', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournal', 'COLUMN', N'IsPrivate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Задача', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournal', 'COLUMN', N'IssueId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Пользователь', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournal', 'COLUMN', N'MemberId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата создания в Redmine', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournal', 'COLUMN', N'RedmineCreated'
GO
