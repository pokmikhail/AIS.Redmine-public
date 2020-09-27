CREATE TABLE [dbo].[IssueStatus]
(
[Id] [int] NOT NULL,
[Code] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NULL,
[Name] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[RedmineName] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[IsAccepted] [bit] NOT NULL,
[IsClosed] [bit] NOT NULL,
[Department] [nvarchar] (50) COLLATE Cyrillic_General_CI_AI NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueStatus] ADD CONSTRAINT [PK_IssueStatus] PRIMARY KEY CLUSTERED  ([Id])
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UQ_IssueStatus_Code] ON [dbo].[IssueStatus] ([Code]) WHERE [Code] IS NOT NULL
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UQ_IssueStatus_Name] ON [dbo].[IssueStatus] ([Name])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Статусы задач', 'SCHEMA', N'dbo', 'TABLE', N'IssueStatus', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код', 'SCHEMA', N'dbo', 'TABLE', N'IssueStatus', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Отдел, отвечающий за задачу в этом статусе', 'SCHEMA', N'dbo', 'TABLE', N'IssueStatus', 'COLUMN', N'Department'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Задача принята?', 'SCHEMA', N'dbo', 'TABLE', N'IssueStatus', 'COLUMN', N'IsAccepted'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Задача закрыта?', 'SCHEMA', N'dbo', 'TABLE', N'IssueStatus', 'COLUMN', N'IsClosed'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Статус', 'SCHEMA', N'dbo', 'TABLE', N'IssueStatus', 'COLUMN', N'Name'
GO
