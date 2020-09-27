using System;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using AIS.Redmine.Models;

namespace AIS.Redmine.Api.Models
{
    public partial class DB : DbContext
    {
        public DB()
            : base()
        {
        }
        public DB(DbContextOptions options)
            : base(options)
        {
        }

        /// <summary>
        /// [dbo].[Configuration] (Настройки системы)
        /// </summary>
        public DbSet<Configuration> Configuration { set; get; }

        /// <summary>
        /// [dbo].[CustomField] (Настраиваемые поля)
        /// </summary>
        public DbSet<CustomField> CustomField { set; get; }

        /// <summary>
        /// [dbo].[Issue] (Задачи)
        /// </summary>
        public DbSet<Issue> Issue { set; get; }

        /// <summary>
        /// [dbo].[IssueCategory] (Категории задач)
        /// </summary>
        public DbSet<IssueCategory> IssueCategory { set; get; }

        /// <summary>
        /// [dbo].[IssueJournal] (История изменений задачи)
        /// </summary>
        public DbSet<IssueJournal> IssueJournal { set; get; }

        /// <summary>
        /// [dbo].[IssuePriority] (Приоритеты задач)
        /// </summary>
        public DbSet<IssuePriority> IssuePriority { set; get; }

        /// <summary>
        /// [dbo].[IssueStatus] (Статусы задач)
        /// </summary>
        public DbSet<IssueStatus> IssueStatus { set; get; }

        /// <summary>
        /// [dbo].[IssueTracker] (Трекеры задач)
        /// </summary>
        public DbSet<IssueTracker> IssueTracker { set; get; }

        /// <summary>
        /// [dbo].[IssueVersion] (Версии)
        /// </summary>
        public DbSet<IssueVersion> IssueVersion { set; get; }

        /// <summary>
        /// [dbo].[Member] (Пользователи Редмайн)
        /// </summary>
        public DbSet<Member> Member { set; get; }

        /// <summary>
        /// [dbo].[Project] (Проекты)
        /// </summary>
        public DbSet<Project> Project { set; get; }

        /// <summary>
        /// [dbo].[TimeEntry] (Трудозатраты)
        /// </summary>
        public DbSet<TimeEntry> TimeEntry { set; get; }

        /// <summary>
        /// [dbo].[TimeEntryType] (Типы трудозатрат)
        /// </summary>
        public DbSet<TimeEntryType> TimeEntryType { set; get; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            _ModelTableNames(modelBuilder);
            _ModelPKs(modelBuilder);
            _ModelGenerated(modelBuilder);
            _ModelDecimal(modelBuilder);
            _ModelConcurrency(modelBuilder);
            _ModelNavigations(modelBuilder);
        }

        private void _ModelTableNames(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Configuration>().ToTable("Configuration", "dbo");
            modelBuilder.Entity<CustomField>().ToTable("CustomField", "dbo");
            modelBuilder.Entity<Issue>().ToTable("Issue", "dbo");
            modelBuilder.Entity<IssueCategory>().ToTable("IssueCategory", "dbo");
            modelBuilder.Entity<IssueJournal>().ToTable("IssueJournal", "dbo");
            modelBuilder.Entity<IssuePriority>().ToTable("IssuePriority", "dbo");
            modelBuilder.Entity<IssueStatus>().ToTable("IssueStatus", "dbo");
            modelBuilder.Entity<IssueTracker>().ToTable("IssueTracker", "dbo");
            modelBuilder.Entity<IssueVersion>().ToTable("IssueVersion", "dbo");
            modelBuilder.Entity<Member>().ToTable("Member", "dbo");
            modelBuilder.Entity<Project>().ToTable("Project", "dbo");
            modelBuilder.Entity<TimeEntry>().ToTable("TimeEntry", "dbo");
            modelBuilder.Entity<TimeEntryType>().ToTable("TimeEntryType", "dbo");
        }

        private void _ModelPKs(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Configuration>().HasKey(i => i.Id);
            modelBuilder.Entity<CustomField>().HasKey(i => i.Id);
            modelBuilder.Entity<Issue>().HasKey(i => i.Id);
            modelBuilder.Entity<IssueCategory>().HasKey(i => i.Id);
            modelBuilder.Entity<IssueJournal>().HasKey(i => i.Id);
            modelBuilder.Entity<IssuePriority>().HasKey(i => i.Id);
            modelBuilder.Entity<IssueStatus>().HasKey(i => i.Id);
            modelBuilder.Entity<IssueTracker>().HasKey(i => i.Id);
            modelBuilder.Entity<IssueVersion>().HasKey(i => i.Id);
            modelBuilder.Entity<Member>().HasKey(i => i.Id);
            modelBuilder.Entity<Project>().HasKey(i => i.Id);
            modelBuilder.Entity<TimeEntry>().HasKey(i => i.Id);
            modelBuilder.Entity<TimeEntryType>().HasKey(i => i.Id);
        }

        private void _ModelGenerated(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Configuration>().Property(x => x.Id).UseIdentityColumn();
            modelBuilder.Entity<CustomField>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<Issue>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<IssueCategory>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<IssueJournal>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<IssuePriority>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<IssueStatus>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<IssueTracker>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<IssueVersion>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<Member>().Property(x => x.Id).UseIdentityColumn();
            modelBuilder.Entity<Project>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<TimeEntry>().Property(x => x.Id).ValueGeneratedNever();
            modelBuilder.Entity<TimeEntryType>().Property(x => x.Id).ValueGeneratedNever();
        }

        private void _ModelDecimal(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Issue>().Property(x => x.EstimatedHours).HasColumnType("decimal(9, 2)");
            modelBuilder.Entity<Issue>().Property(x => x.TotalEstimatedHours).HasColumnType("decimal(9, 2)");
            modelBuilder.Entity<Issue>().Property(x => x.SpentHours).HasColumnType("decimal(9, 2)");
            modelBuilder.Entity<Issue>().Property(x => x.TotalSpentHours).HasColumnType("decimal(9, 2)");
            modelBuilder.Entity<Project>().Property(x => x.ContractHoursPerMonth).HasColumnType("decimal(9, 1)");
            modelBuilder.Entity<TimeEntry>().Property(x => x.Hours).HasColumnType("decimal(9, 2)");
        }

        private void _ModelConcurrency(ModelBuilder modelBuilder)
        {
        }

        private void _ModelNavigations(ModelBuilder modelBuilder)
        {
        }

    }
}
