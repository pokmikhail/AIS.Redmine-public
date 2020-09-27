namespace AIS.Redmine.Api.Models
{
    public class ImportStats
    {
        public int total { get; set; }
        public int added { get; set; }
        public int updated { get; set; }
        public int deleted { get; set; }

        public void Add(ImportStats anotherCounter)
        {
            if (anotherCounter == null)
                return;

            total += anotherCounter.total;
            added += anotherCounter.added;
            updated += anotherCounter.updated;
            deleted += anotherCounter.deleted;
        }
    }

    public class ImportCoreDataStats
    {
        public ImportStats Users { get; set; }
        public ImportStats Statuses { get; set; }
        public ImportStats Priorities { get; set; }
        public ImportStats TimeEntries { get; set; }
        public ImportStats CustomFields { get; set; }
        public ImportStats IssueTrackers { get; set; }
        public ImportStats Projects { get; set; }
        public ImportStats Versions { get; set; }

        public ImportCoreDataStats()
        {
            Users = new ImportStats();
            Statuses = new ImportStats();
            Priorities = new ImportStats();
            TimeEntries = new ImportStats();
            CustomFields = new ImportStats();
            IssueTrackers = new ImportStats();
            Projects = new ImportStats();
            Versions = new ImportStats();
        }
    }

    public class ImportIssuesStats
    {
        public ImportStats List { get; set; }
        public ImportStats Details { get; set; }

        public ImportIssuesStats()
        {
            List = new ImportStats();
            Details = new ImportStats();
        }
    }
}
