CREATE TABLE [dbo].[Configuration]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[Code] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Value] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NULL,
[Name] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Description] [nvarchar] (2000) COLLATE Cyrillic_General_CI_AI NULL,
[Created] [datetimeoffset] NOT NULL,
[Updated] [datetimeoffset] NOT NULL
)
GO
ALTER TABLE [dbo].[Configuration] ADD CONSTRAINT [PK_Configuration] PRIMARY KEY CLUSTERED  ([Id])
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UQ_Configuration_Code] ON [dbo].[Configuration] ([Code])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Настройки системы', 'SCHEMA', N'dbo', 'TABLE', N'Configuration', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код параметра', 'SCHEMA', N'dbo', 'TABLE', N'Configuration', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Описание', 'SCHEMA', N'dbo', 'TABLE', N'Configuration', 'COLUMN', N'Description'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование параметра', 'SCHEMA', N'dbo', 'TABLE', N'Configuration', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Значение параметра', 'SCHEMA', N'dbo', 'TABLE', N'Configuration', 'COLUMN', N'Value'
GO
