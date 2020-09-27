CREATE TABLE [dbo].[IssueRelation]
(
[Id] [int] NOT NULL,
[IssueId] [int] NOT NULL,
[IssueToId] [int] NOT NULL,
[Type] [nvarchar] (50) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Delay] [int] NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueRelation] ADD CONSTRAINT [PK_IssueRelation] PRIMARY KEY CLUSTERED  ([Id])
GO
CREATE NONCLUSTERED INDEX [IssueRelation_IssueId] ON [dbo].[IssueRelation] ([IssueId])
GO
CREATE NONCLUSTERED INDEX [IssueRelation_IssueToId] ON [dbo].[IssueRelation] ([IssueToId])
GO
ALTER TABLE [dbo].[IssueRelation] ADD CONSTRAINT [FK_IssueRelation_Issue_Issue] FOREIGN KEY ([IssueId]) REFERENCES [dbo].[Issue] ([Id])
GO
ALTER TABLE [dbo].[IssueRelation] ADD CONSTRAINT [FK_IssueRelation_Issue_IssueTo] FOREIGN KEY ([IssueToId]) REFERENCES [dbo].[Issue] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Связанные задачи', 'SCHEMA', N'dbo', 'TABLE', N'IssueRelation', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Задержка (для предыдущих/следующих задач)', 'SCHEMA', N'dbo', 'TABLE', N'IssueRelation', 'COLUMN', N'Delay'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Задача', 'SCHEMA', N'dbo', 'TABLE', N'IssueRelation', 'COLUMN', N'IssueId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Связанная задача', 'SCHEMA', N'dbo', 'TABLE', N'IssueRelation', 'COLUMN', N'IssueToId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код типа связи. Возможные значения: relates, duplicates, duplicated, blocks, blocked, precedes, follows, copied_to, copied_from', 'SCHEMA', N'dbo', 'TABLE', N'IssueRelation', 'COLUMN', N'Type'
GO
