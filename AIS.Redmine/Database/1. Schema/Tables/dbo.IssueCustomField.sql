CREATE TABLE [dbo].[IssueCustomField]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[IssueId] [int] NOT NULL,
[CustomFieldId] [int] NOT NULL,
[Value] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssueCustomField] ADD CONSTRAINT [PK_IssueCustomField] PRIMARY KEY CLUSTERED  ([Id])
GO
CREATE NONCLUSTERED INDEX [IssueCustomField_Isssue_CustomField] ON [dbo].[IssueCustomField] ([IssueId], [CustomFieldId])
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UQ_IssueCustomField] ON [dbo].[IssueCustomField] ([IssueId], [CustomFieldId])
GO
ALTER TABLE [dbo].[IssueCustomField] ADD CONSTRAINT [FK_IssueCustomField_CustomField] FOREIGN KEY ([CustomFieldId]) REFERENCES [dbo].[CustomField] ([Id])
GO
ALTER TABLE [dbo].[IssueCustomField] ADD CONSTRAINT [FK_IssueCustomField_Issue] FOREIGN KEY ([IssueId]) REFERENCES [dbo].[Issue] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Настраиваемые поля для задач', 'SCHEMA', N'dbo', 'TABLE', N'IssueCustomField', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Поле', 'SCHEMA', N'dbo', 'TABLE', N'IssueCustomField', 'COLUMN', N'CustomFieldId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Задача', 'SCHEMA', N'dbo', 'TABLE', N'IssueCustomField', 'COLUMN', N'IssueId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Значение', 'SCHEMA', N'dbo', 'TABLE', N'IssueCustomField', 'COLUMN', N'Value'
GO
