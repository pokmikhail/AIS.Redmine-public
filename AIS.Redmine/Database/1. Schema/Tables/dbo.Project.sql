CREATE TABLE [dbo].[Project]
(
[Id] [int] NOT NULL,
[ParentId] [int] NULL,
[Code] [nvarchar] (50) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Name] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[RedmineName] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[HasRevisions] [bit] NOT NULL,
[HasVersions] [bit] NOT NULL,
[InstanceCode] [nvarchar] (50) COLLATE Cyrillic_General_CI_AI NULL,
[InstanceName] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NULL,
[ContractNumber] [nvarchar] (1000) COLLATE Cyrillic_General_CI_AI NULL,
[ContractExpirationDate] [date] NULL,
[ContractHoursPerMonth] [decimal] (9, 1) NULL,
[GisCertificateExpirationDate] [date] NULL,
[IsDeleted] [bit] NOT NULL,
[RedmineCreated] [datetimeoffset] (0) NOT NULL,
[LastReceivedDate] [datetimeoffset] (0) NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[Project] ADD CONSTRAINT [PK_Project] PRIMARY KEY CLUSTERED  ([Id])
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_UQ_Project_Code] ON [dbo].[Project] ([Code])
GO
ALTER TABLE [dbo].[Project] ADD CONSTRAINT [FK_Project_Project] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[Project] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Проекты', 'SCHEMA', N'dbo', 'TABLE', N'Project', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'Code'
GO
EXEC sp_addextendedproperty N'MS_Description', N'День, до которого действует договор поддержки (если договор не пролонгируется автоматически)', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'ContractExpirationDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Количество включенных в договор поддержки часов в месяц', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'ContractHoursPerMonth'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Номер договора поддержки', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'ContractNumber'
GO
EXEC sp_addextendedproperty N'MS_Description', N'День, до которого действует сертификат сервиса обмена с ГИС ЖКХ (если обмен настроен)', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'GisCertificateExpirationDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Работать с ревизиями для проекта?', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'HasRevisions'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Работать с верчиями для проекта?', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'HasVersions'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Код площадки', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'InstanceCode'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование площадки', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'InstanceName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Запись удалена?', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'IsDeleted'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата последнего приёма данных из Redmine', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'LastReceivedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Родительский проект', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'ParentId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата создания в Редмайн', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'RedmineCreated'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Наименование в Редмайн', 'SCHEMA', N'dbo', 'TABLE', N'Project', 'COLUMN', N'RedmineName'
GO
