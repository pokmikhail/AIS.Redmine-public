CREATE TABLE [dbo].[IssueJournalDetails]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[IssueJournalId] [int] NOT NULL,
[Type] [nvarchar] (100) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Name] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[OldValue] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NULL,
[NewValue] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueJournalDetails] ADD CONSTRAINT [PK_IssueJournalDetails] PRIMARY KEY CLUSTERED  ([Id])
GO
ALTER TABLE [dbo].[IssueJournalDetails] ADD CONSTRAINT [FK_IssueJournalDetails_IssueJournal] FOREIGN KEY ([IssueJournalId]) REFERENCES [dbo].[IssueJournal] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'История изменений задачи. Изменённые поля', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournalDetails', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Запись истории изменений задачи', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournalDetails', 'COLUMN', N'IssueJournalId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование параметра', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournalDetails', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Новое значение', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournalDetails', 'COLUMN', N'NewValue'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Старое значение', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournalDetails', 'COLUMN', N'OldValue'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Тип параметра', 'SCHEMA', N'dbo', 'TABLE', N'IssueJournalDetails', 'COLUMN', N'Type'
GO
