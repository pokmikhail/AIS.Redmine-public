CREATE TABLE [dbo].[Member]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[RedmineId] [int] NOT NULL,
[LeadMemberId] [int] NULL,
[Name] [nvarchar] (100) COLLATE Cyrillic_General_CI_AI NOT NULL,
[NameAndInitials] [nvarchar] (200) COLLATE Cyrillic_General_CI_AI NOT NULL,
[RedmineLogin] [nvarchar] (100) COLLATE Cyrillic_General_CI_AI NOT NULL,
[Department] [nvarchar] (50) COLLATE Cyrillic_General_CI_AI NULL,
[IsDeleted] [bit] NOT NULL,
[RedmineCreated] [datetimeoffset] (0) NOT NULL,
[LastReceivedDate] [datetimeoffset] (0) NULL,
[Created] [datetimeoffset] (0) NOT NULL,
[Updated] [datetimeoffset] (0) NOT NULL
)
GO
ALTER TABLE [dbo].[Member] ADD CONSTRAINT [PK_Member] PRIMARY KEY CLUSTERED  ([Id])
GO
CREATE NONCLUSTERED INDEX [IX_Member_RedmineId] ON [dbo].[Member] ([RedmineId]) INCLUDE ([Id])
GO
ALTER TABLE [dbo].[Member] ADD CONSTRAINT [FK_Member_Member_LeadMemberId] FOREIGN KEY ([LeadMemberId]) REFERENCES [dbo].[Member] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'Пользователи Редмайн', 'SCHEMA', N'dbo', 'TABLE', N'Member', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Отдел', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'Department'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Запись удалена?', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'IsDeleted'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата последнего приёма данных из Redmine', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'LastReceivedDate'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Руководитель', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'LeadMemberId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ФИО', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'Name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Фамилия и инициалы', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'NameAndInitials'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Дата создания в Редмайн', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'RedmineCreated'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Id в Редмайн', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'RedmineId'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Логин в Редмайн', 'SCHEMA', N'dbo', 'TABLE', N'Member', 'COLUMN', N'RedmineLogin'
GO
