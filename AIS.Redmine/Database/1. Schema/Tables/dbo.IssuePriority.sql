CREATE TABLE [dbo].[IssuePriority]
(
[Id] [int] NOT NULL,
[Code] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NULL,
[Name] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Sort] [int] NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[IssuePriority] ADD CONSTRAINT [PK_IssuePriority] PRIMARY KEY CLUSTERED  ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Приоритеты задач', 'SCHEMA', N'dbo', 'TABLE', N'IssuePriority', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код', 'SCHEMA', N'dbo', 'TABLE', N'IssuePriority', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Приоритет', 'SCHEMA', N'dbo', 'TABLE', N'IssuePriority', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Приоритет числовой', 'SCHEMA', N'dbo', 'TABLE', N'IssuePriority', 'COLUMN', N'Sort'
GO
