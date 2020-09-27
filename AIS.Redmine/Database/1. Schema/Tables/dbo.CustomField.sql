CREATE TABLE [dbo].[CustomField]
(
[Id] [int] NOT NULL,
[Name] [nvarchar] (500) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Type] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Format] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[IsRequired] [bit] NOT NULL,
[IsMultiple] [bit] NOT NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[CustomField] ADD CONSTRAINT [PK_CustomField] PRIMARY KEY CLUSTERED  ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Настраиваемые поля', 'SCHEMA', N'dbo', 'TABLE', N'CustomField', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код формата', 'SCHEMA', N'dbo', 'TABLE', N'CustomField', 'COLUMN', N'Format'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Множественное?', 'SCHEMA', N'dbo', 'TABLE', N'CustomField', 'COLUMN', N'IsMultiple'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Обязательное?', 'SCHEMA', N'dbo', 'TABLE', N'CustomField', 'COLUMN', N'IsRequired'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование', 'SCHEMA', N'dbo', 'TABLE', N'CustomField', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код типа', 'SCHEMA', N'dbo', 'TABLE', N'CustomField', 'COLUMN', N'Type'
GO
