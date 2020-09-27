CREATE TABLE [dbo].[TimeEntryType]
(
[Id] [int] NOT NULL,
[Code] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NULL,
[Name] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[TimeEntryType] ADD CONSTRAINT [PK_TimeEntryType] PRIMARY KEY CLUSTERED  ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Типы трудозатрат', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntryType', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntryType', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Тип', 'SCHEMA', N'dbo', 'TABLE', N'TimeEntryType', 'COLUMN', N'Name'
GO
