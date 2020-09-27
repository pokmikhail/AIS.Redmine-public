CREATE TABLE [dbo].[IssueRevision]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[IssueId] [int] NOT NULL,
[Revision] [nvarchar] (50) COLLATE Cyrillic_General_CI_AI NOT NULL,
[MemberId] [int] NULL,
[Comment] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NULL,
[RedmineCommitted] [datetimeoffset] (0) NOT NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueRevision] ADD CONSTRAINT [PK_IssueRevision] PRIMARY KEY CLUSTERED  ([Id])
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UQ_IssueRevision] ON [dbo].[IssueRevision] ([IssueId], [Revision])
GO
ALTER TABLE [dbo].[IssueRevision] ADD CONSTRAINT [FK_IssueRevision_Issue] FOREIGN KEY ([IssueId]) REFERENCES [dbo].[Issue] ([Id])
GO
ALTER TABLE [dbo].[IssueRevision] ADD CONSTRAINT [FK_IssueRevision_Member] FOREIGN KEY ([MemberId]) REFERENCES [dbo].[Member] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Коммиты к задачам', 'SCHEMA', N'dbo', 'TABLE', N'IssueRevision', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Комментарий', 'SCHEMA', N'dbo', 'TABLE', N'IssueRevision', 'COLUMN', N'Comment'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Пользователь', 'SCHEMA', N'dbo', 'TABLE', N'IssueRevision', 'COLUMN', N'MemberId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата коммита из Redmine', 'SCHEMA', N'dbo', 'TABLE', N'IssueRevision', 'COLUMN', N'RedmineCommitted'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Коммит', 'SCHEMA', N'dbo', 'TABLE', N'IssueRevision', 'COLUMN', N'Revision'
GO
