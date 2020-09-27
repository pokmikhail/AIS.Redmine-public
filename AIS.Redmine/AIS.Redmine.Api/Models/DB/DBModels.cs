using System;
using System.Collections.Generic;

namespace AIS.Redmine.Models
{
    /// <summary>
    /// Настройки системы
    /// </summary>
    public partial class Configuration
    {
        public int Id { set; get; }

        /// <summary>
        /// Код параметра
        /// </summary>
        public string Code { set; get; }

        /// <summary>
        /// Значение параметра
        /// </summary>
        public string Value { set; get; }

        /// <summary>
        /// Наименование параметра
        /// </summary>
        public string Name { set; get; }

        /// <summary>
        /// Описание
        /// </summary>
        public string Description { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Настраиваемые поля
    /// </summary>
    public partial class CustomField
    {
        public int Id { set; get; }

        /// <summary>
        /// Наименование
        /// </summary>
        public string Name { set; get; }

        /// <summary>
        /// Код типа
        /// </summary>
        public string Type { set; get; }

        /// <summary>
        /// Код формата
        /// </summary>
        public string Format { set; get; }

        /// <summary>
        /// Обязательное?
        /// </summary>
        public bool IsRequired { set; get; }

        /// <summary>
        /// Множественное?
        /// </summary>
        public bool IsMultiple { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Задачи
    /// </summary>
    public partial class Issue
    {
        public int Id { set; get; }

        /// <summary>
        /// Проект
        /// </summary>
        public int ProjectId { set; get; }

        /// <summary>
        /// Трекер
        /// </summary>
        public int TrackerId { set; get; }

        /// <summary>
        /// Статус
        /// </summary>
        public int StatusId { set; get; }

        /// <summary>
        /// Приоритет
        /// </summary>
        public int PriorityId { set; get; }

        /// <summary>
        /// Автор
        /// </summary>
        public int? AuthorMemberId { set; get; }

        /// <summary>
        /// Назначена
        /// </summary>
        public int? AssignedToMemberId { set; get; }

        /// <summary>
        /// Родительская задача
        /// </summary>
        public int? ParentId { set; get; }

        /// <summary>
        /// Категория
        /// </summary>
        public int? CategoryId { set; get; }

        /// <summary>
        /// Версия
        /// </summary>
        public int? VersionId { set; get; }

        /// <summary>
        /// Тема
        /// </summary>
        public string Subject { set; get; }

        /// <summary>
        /// Описание
        /// </summary>
        public string Description { set; get; }

        /// <summary>
        /// Дата начала
        /// </summary>
        public DateTime? StartDate { set; get; }

        /// <summary>
        /// Дата завершения
        /// </summary>
        public DateTime? DueDate { set; get; }

        /// <summary>
        /// Процент готовности
        /// </summary>
        public int? DoneRatio { set; get; }

        /// <summary>
        /// Оценка времени, ч
        /// </summary>
        public decimal? EstimatedHours { set; get; }

        /// <summary>
        /// Оценка времени, включая подзадачи, ч
        /// </summary>
        public decimal? TotalEstimatedHours { set; get; }

        /// <summary>
        /// Затрачено времени, ч
        /// </summary>
        public decimal? SpentHours { set; get; }

        /// <summary>
        /// Затрачено времени, включая подзадачи, ч
        /// </summary>
        public decimal? TotalSpentHours { set; get; }

        /// <summary>
        /// Дата создания в Редмайне
        /// </summary>
        public DateTimeOffset RedmineCreated { set; get; }

        /// <summary>
        /// Дата обновления Дата создания в Редмайне
        /// </summary>
        public DateTimeOffset RedmineUpdated { set; get; }

        /// <summary>
        /// Дата закрытия в Редмайне
        /// </summary>
        public DateTimeOffset? RedmineClosed { set; get; }

        /// <summary>
        /// Последнее изменение по журналу изменений
        /// </summary>
        public DateTimeOffset LastHistoryDate { set; get; }

        /// <summary>
        /// Дата последнего приёма данных из Redmine
        /// </summary>
        public DateTimeOffset? LastReceivedDate { set; get; }

        /// <summary>
        /// Удалена?ы
        /// </summary>
        public bool IsDeleted { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Категории задач
    /// </summary>
    public partial class IssueCategory
    {
        public int Id { set; get; }

        /// <summary>
        /// Проект
        /// </summary>
        public int ProjectId { set; get; }

        /// <summary>
        /// Наименование
        /// </summary>
        public string Name { set; get; }

        public string RedmineName { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// История изменений задачи
    /// </summary>
    public partial class IssueJournal
    {
        public int Id { set; get; }

        /// <summary>
        /// Задача
        /// </summary>
        public int IssueId { set; get; }

        /// <summary>
        /// Пользователь
        /// </summary>
        public int MemberId { set; get; }

        /// <summary>
        /// Примечание
        /// </summary>
        public string Comment { set; get; }

        /// <summary>
        /// Приватный комментарий?
        /// </summary>
        public bool IsPrivate { set; get; }

        /// <summary>
        /// Удалена?
        /// </summary>
        public bool IsDeleted { set; get; }

        /// <summary>
        /// Дата создания в Redmine
        /// </summary>
        public DateTimeOffset RedmineCreated { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Приоритеты задач
    /// </summary>
    public partial class IssuePriority
    {
        public int Id { set; get; }

        /// <summary>
        /// Код
        /// </summary>
        public string Code { set; get; }

        /// <summary>
        /// Приоритет
        /// </summary>
        public string Name { set; get; }

        /// <summary>
        /// Приоритет числовой
        /// </summary>
        public int? Sort { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Статусы задач
    /// </summary>
    public partial class IssueStatus
    {
        public int Id { set; get; }

        /// <summary>
        /// Код
        /// </summary>
        public string Code { set; get; }

        /// <summary>
        /// Статус
        /// </summary>
        public string Name { set; get; }

        public string RedmineName { set; get; }

        /// <summary>
        /// Задача принята?
        /// </summary>
        public bool IsAccepted { set; get; }

        /// <summary>
        /// Задача закрыта?
        /// </summary>
        public bool IsClosed { set; get; }

        /// <summary>
        /// Отдел, отвечающий за задачу в этом статусе
        /// </summary>
        public string Department { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Трекеры задач
    /// </summary>
    public partial class IssueTracker
    {
        public int Id { set; get; }

        /// <summary>
        /// Наименование
        /// </summary>
        public string Name { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Версии
    /// </summary>
    public partial class IssueVersion
    {
        public int Id { set; get; }

        /// <summary>
        /// Проект
        /// </summary>
        public int ProjectId { set; get; }

        /// <summary>
        /// Наименование
        /// </summary>
        public string Name { set; get; }

        /// <summary>
        /// Дата выхода
        /// </summary>
        public DateTime? DueDate { set; get; }

        /// <summary>
        /// Версия закрыта?
        /// </summary>
        public bool IsClosed { set; get; }

        /// <summary>
        /// Запись удалена?
        /// </summary>
        public bool IsDeleted { set; get; }

        /// <summary>
        /// Дата создания в Редмайн
        /// </summary>
        public DateTimeOffset RedmineCreated { set; get; }

        /// <summary>
        /// Дата обновления в Редмайн
        /// </summary>
        public DateTimeOffset RedmineUpdated { set; get; }

        /// <summary>
        /// Дата последнего приёма данных из Redmine
        /// </summary>
        public DateTimeOffset? LastReceivedDate { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Пользователи Редмайн
    /// </summary>
    public partial class Member
    {
        public int Id { set; get; }

        /// <summary>
        /// Id в Редмайн
        /// </summary>
        public int RedmineId { set; get; }

        /// <summary>
        /// Руководитель
        /// </summary>
        public int? LeadMemberId { set; get; }

        /// <summary>
        /// ФИО
        /// </summary>
        public string Name { set; get; }

        /// <summary>
        /// Фамилия и инициалы
        /// </summary>
        public string NameAndInitials { set; get; }

        /// <summary>
        /// Логин в Редмайн
        /// </summary>
        public string RedmineLogin { set; get; }

        /// <summary>
        /// Отдел
        /// </summary>
        public string Department { set; get; }

        /// <summary>
        /// Запись удалена?
        /// </summary>
        public bool IsDeleted { set; get; }

        /// <summary>
        /// Дата создания в Редмайн
        /// </summary>
        public DateTimeOffset RedmineCreated { set; get; }

        /// <summary>
        /// Дата последнего приёма данных из Redmine
        /// </summary>
        public DateTimeOffset? LastReceivedDate { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Проекты
    /// </summary>
    public partial class Project
    {
        public int Id { set; get; }

        /// <summary>
        /// Родительский проект
        /// </summary>
        public int? ParentId { set; get; }

        /// <summary>
        /// Код
        /// </summary>
        public string Code { set; get; }

        /// <summary>
        /// Наименование
        /// </summary>
        public string Name { set; get; }

        /// <summary>
        /// Наименование в Редмайн
        /// </summary>
        public string RedmineName { set; get; }

        /// <summary>
        /// Работать с ревизиями для проекта?
        /// </summary>
        public bool HasRevisions { set; get; }

        /// <summary>
        /// Работать с верчиями для проекта?
        /// </summary>
        public bool HasVersions { set; get; }

        /// <summary>
        /// Код площадки
        /// </summary>
        public string InstanceCode { set; get; }

        /// <summary>
        /// Наименование площадки
        /// </summary>
        public string InstanceName { set; get; }

        /// <summary>
        /// Номер договора поддержки
        /// </summary>
        public string ContractNumber { set; get; }

        /// <summary>
        /// День, до которого действует договор поддержки (если договор не пролонгируется автоматически)
        /// </summary>
        public DateTime? ContractExpirationDate { set; get; }

        /// <summary>
        /// Количество включенных в договор поддержки часов в месяц
        /// </summary>
        public decimal? ContractHoursPerMonth { set; get; }

        /// <summary>
        /// День, до которого действует сертификат сервиса обмена с ГИС ЖКХ (если обмен настроен)
        /// </summary>
        public DateTime? GisCertificateExpirationDate { set; get; }

        /// <summary>
        /// Запись удалена?
        /// </summary>
        public bool IsDeleted { set; get; }

        /// <summary>
        /// Дата создания в Редмайн
        /// </summary>
        public DateTimeOffset RedmineCreated { set; get; }

        /// <summary>
        /// Дата последнего приёма данных из Redmine
        /// </summary>
        public DateTimeOffset? LastReceivedDate { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Трудозатраты
    /// </summary>
    public partial class TimeEntry
    {
        public int Id { set; get; }

        /// <summary>
        /// Проект
        /// </summary>
        public int ProjectId { set; get; }

        /// <summary>
        /// Задача
        /// </summary>
        public int IssueId { set; get; }

        /// <summary>
        /// Пользователь
        /// </summary>
        public int MemberId { set; get; }

        /// <summary>
        /// Дата
        /// </summary>
        public DateTime Date { set; get; }

        /// <summary>
        /// Тип
        /// </summary>
        public int TypeId { set; get; }

        /// <summary>
        /// Часы
        /// </summary>
        public decimal Hours { set; get; }

        /// <summary>
        /// Комметарий
        /// </summary>
        public string Comments { set; get; }

        /// <summary>
        /// Дата создания в Redmine
        /// </summary>
        public DateTimeOffset RedmineCreated { set; get; }

        /// <summary>
        /// Дата обновления в Redmine
        /// </summary>
        public DateTimeOffset RedmineUpdated { set; get; }

        /// <summary>
        /// Дата последнего приёма данных из Redmine
        /// </summary>
        public DateTimeOffset? LastReceivedDate { set; get; }

        /// <summary>
        /// Удалено?
        /// </summary>
        public bool IsDeleted { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

    /// <summary>
    /// Типы трудозатрат
    /// </summary>
    public partial class TimeEntryType
    {
        public int Id { set; get; }

        /// <summary>
        /// Код
        /// </summary>
        public string Code { set; get; }

        /// <summary>
        /// Тип
        /// </summary>
        public string Name { set; get; }

        public DateTimeOffset Created { set; get; }

        public DateTimeOffset Updated { set; get; }
    }

}
