using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Threading.Tasks.Dataflow;
using System.Xml.Linq;
using AIS.Redmine.Api.Models;
using AIS.Redmine.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Internal;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace AIS.Redmine.Api.Controllers
{
    /// <summary>
    /// Redmine import routines
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Produces("application/json")]
    public class RedmineController : ControllerBase
    {
        private readonly ILogger<TestController> _logger;
        private readonly IConfigurationService _config;
        private readonly IServiceProvider _services;
        private readonly RedmineXmlImporter _importer;

        private readonly int _limit = 100;
        private readonly string _redmineUrl;
        private readonly string _redmineApiKey;
        private readonly ExecutionDataflowBlockOptions _opts;

        public RedmineController(
            ILogger<TestController> logger,
            IConfigurationService configuration,
            IServiceProvider services,
            RedmineXmlImporter importer
            )
        {
            _logger = logger;
            _config = configuration;
            _services = services;
            _importer = importer;

            // Init
            _redmineUrl = _config.Get("Redmine:Url");
            _redmineApiKey = _config.Get("Redmine:ApiKey");

            var _reservedThreads = 2;
            _opts = new ExecutionDataflowBlockOptions();

            if (Environment.ProcessorCount > _reservedThreads)
                _opts.MaxDegreeOfParallelism = Environment.ProcessorCount - _reservedThreads;

            // Checks
            if (string.IsNullOrWhiteSpace(_redmineUrl))
                throw new Exception("Не настроен адрес сайта Redmine");
            if (string.IsNullOrWhiteSpace(_redmineApiKey))
                throw new Exception("Не настроен Apikey для доступа к Redmine");
        }

        /// <summary>
        /// Imports core references: Members, Projects, Time entry types, Versions, Issue statuses/priorities/trackers/categories/custom fields.
        /// </summary>
        [HttpPost("ImportCoreData")]
        public async Task<ApiResponse<ImportCoreDataStats>> ImportCoreData()
        {
            // based on http://www.redmine.org/projects/redmine/wiki/Rest_api
            var sw = new Stopwatch();
            sw.Start();

            var result = new ImportCoreDataStats();

            // init

            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();

            var projectMaxDate = _db.Project.Max(d => (DateTimeOffset?)d.LastReceivedDate) ?? DateTimeOffset.MinValue;
            var versionMaxDate = _db.IssueVersion.Max(d => (DateTimeOffset?)d.LastReceivedDate) ?? DateTimeOffset.MinValue;
            var memberMaxDate = _db.Member.Max(d => (DateTimeOffset?)d.LastReceivedDate) ?? DateTimeOffset.MinValue;

            // To make this part parallel we need to use diffenet DB context in each _import method
            var queue1 = new Dictionary<string, Task<ImportStats>> {
                { "activeUsers", _importUsers(true) },// Get active users
                { "lockedUsers", _importUsers(false) },// Get locked users
                { "statuses", _importIssueStatuses() },
                { "priorities", _importIssuePriorities() },
                { "timeEntries", _importTimeEntryTypes() },
                { "customFields", _importCustomFields() },
                { "issueTrackers", _importIssueTrackers() },
                { "projects", _importProjects() }
            };

            await Task.WhenAll(queue1.Values.AsEnumerable());
            _logger.LogDebug($"Core 1 - {sw.Elapsed}");

            // depends on projects
            var queue2 = new Dictionary<string, Task<ImportStats>> {
                { "versions", _importVersions() }
            };

            await Task.WhenAll(queue2.Values.AsEnumerable());
            _logger.LogDebug($"Core 2 - {sw.Elapsed}");

            // store results
            result.Users.Add(queue1["activeUsers"].Result);
            result.Users.Add(queue1["lockedUsers"].Result);
            result.Statuses.Add(queue1["statuses"].Result);
            result.Priorities.Add(queue1["priorities"].Result);
            result.TimeEntries.Add(queue1["timeEntries"].Result);
            result.CustomFields.Add(queue1["customFields"].Result);
            result.IssueTrackers.Add(queue1["issueTrackers"].Result);
            result.Projects.Add(queue1["projects"].Result);

            result.Versions.Add(queue2["versions"].Result);

            // Find deleted members
            {
                var query = _db.Member
                    .Where(d => !d.IsDeleted)
                    .Where(d => d.LastReceivedDate == null || d.LastReceivedDate <= versionMaxDate)
                    ;

                var list = query.ToList();

                var now = DateTimeOffset.Now;
                foreach (var item in list)
                {
                    item.IsDeleted = true;
                    item.Updated = now;
                }

                await _db.SaveChangesAsync();
                result.Users.deleted += list.Count;
                _logger.LogDebug($"Members import. {list.Count} marked as deleted.");
            }

            // Find deleted projects
            {
                var query = _db.Project
                    .Where(d => !d.IsDeleted)
                    .Where(d => d.LastReceivedDate == null || d.LastReceivedDate <= projectMaxDate)
                    ;

                var list = query.ToList();

                var now = DateTimeOffset.Now;
                foreach (var item in list)
                {
                    item.IsDeleted = true;
                    item.Updated = now;
                }

                await _db.SaveChangesAsync();
                result.Projects.deleted += list.Count;
                _logger.LogDebug($"Projects import. {list.Count} marked as deleted.");
            }

            // Find deleted versions
            {
                var query = _db.IssueVersion
                    .Where(d => !d.IsDeleted)
                    .Where(d => d.LastReceivedDate == null || d.LastReceivedDate <= versionMaxDate)
                    ;

                var list = query.ToList();

                var now = DateTimeOffset.Now;
                foreach (var item in list)
                {
                    item.IsDeleted = true;
                    item.Updated = now;
                }

                await _db.SaveChangesAsync();
                result.Versions.deleted += list.Count;
                _logger.LogDebug($"Versions import. {list.Count} marked as deleted.");
            }

            _logger.LogDebug($"Core 3. Deleted processsing - {sw.Elapsed}");

            sw.Stop();

            return ApiResponse.Create(result);
        }

        /// <summary>
        /// Imports all issues from Redmine. This can take up to few hours!
        /// </summary>
        /// <returns></returns>
        [HttpPost("ImportIssues/All")]
        public async Task<ApiResponse<ImportIssuesStats>> ImportAllIssues()
        {
            return await ImportIssues(null, null);
        }

        /// <summary>
        /// Imports updated issues from Redmine.
        /// </summary>
        /// <returns></returns>
        [HttpPost("ImportIssues/New")]
        public async Task<ApiResponse<ImportIssuesStats>> ImportNewIssues()
        {
            DateTime? dateStartUtc = null;

            var cfgMax = _config.GetDateTimeOffset("System:IssueMaxUpdated");

            if (cfgMax.HasValue)
                dateStartUtc = cfgMax.Value.DateTime;

            return await ImportIssues(dateStartUtc, null);
        }

        /// <summary>
        /// Imports updated in period issues from Redmine 
        /// </summary>
        /// <param name="dateStartUtc">Period start for issue import, UTC</param>
        /// <param name="dateEndUtc">Period end for issue import, UTC</param>
        /// <returns></returns>
        [HttpPost("ImportIssues/Custom")]
        public async Task<ApiResponse<ImportIssuesStats>> ImportIssues(
            DateTime? dateStartUtc,
            DateTime? dateEndUtc
            )
        {
            var sw = new Stopwatch();
            sw.Start();
            _logger.LogInformation("Issues import. Start. "
                + $"{(dateStartUtc.HasValue ? dateStartUtc.Value.ToString("u") : "[ 0 AD ]")} - {(dateEndUtc.HasValue ? dateEndUtc.Value.ToString("u") : "[ now ]")}"
                );

            // OVERVIEW
            // 1.Import issue list
            // 2.Import issue details

            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();

            // init
            var oldMaxDate = _db.Issue.Max(d => (DateTimeOffset?)d.LastReceivedDate) ?? DateTimeOffset.MinValue;
            var result = new ImportIssuesStats();

            // step 1
            result.List.Add(await _importIssueList(dateStartUtc, dateEndUtc));

            // get maxRemoteUpdate to store later
            var newMaxUpdated = await _db.Issue
                .Where(d => d.LastReceivedDate > oldMaxDate)
                .MaxAsync(d => (DateTimeOffset?)d.RedmineUpdated)
                ;

            // step 2
            // get all updated issues
            var issueIds = (
                from d in _db.Issue
                where d.LastReceivedDate > oldMaxDate
                orderby d.Id
                select d.Id
                ).ToList();

            result.Details.Add(await _importIssueDetails(issueIds));

            // post-process
            // store remoteMaxUpdated for UpdateNew method
            if (!dateEndUtc.HasValue)
            {
                DateTimeOffset? cfgMaxUpdated = _config.GetDateTimeOffset("System:IssueMaxUpdated");

                if (newMaxUpdated.HasValue && (!cfgMaxUpdated.HasValue || cfgMaxUpdated < newMaxUpdated))
                    await _config.SetAndSaveAsync("System:IssueMaxUpdated", newMaxUpdated);
            }

            // Find deleted issues
            {
                var query = _db.Issue
                    .Where(d => !d.IsDeleted)
                    .Where(d => d.LastReceivedDate == null || d.LastReceivedDate <= oldMaxDate)
                    ;

                if (dateStartUtc.HasValue)
                {
                    var dateOffset = new DateTimeOffset(dateStartUtc.Value, TimeSpan.FromSeconds(0));
                    query = query.Where(d => d.RedmineUpdated >= dateOffset);
                }
                if (dateEndUtc.HasValue)
                {
                    var dateOffset = new DateTimeOffset(dateEndUtc.Value, TimeSpan.FromSeconds(0));
                    query = query.Where(d => d.RedmineUpdated < dateOffset);
                }

                var list = query.ToList();

                var now = DateTimeOffset.Now;
                foreach (var item in list)
                {
                    item.IsDeleted = true;
                    item.Updated = now;
                }

                await _db.SaveChangesAsync();
                _logger.LogDebug($"Issues import. {list.Count} marked as deleted.");
            }

            sw.Stop();
            _logger.LogDebug($"Issues import. Finish. {sw.Elapsed}");

            return ApiResponse.Create(result);
        }

        /// <summary>
        /// Importss all time entries from Redmine. This can take up to few hours!
        /// </summary>
        /// <returns></returns>
        [HttpPost("ImportTimeEntries/All")]
        public async Task<ApiResponse<ImportStats>> ImportAllTimeEntries()
        {
            return await ImportTimeEntries(null, null);
        }

        /// <summary>
        /// Imports updated time entries from Redmine. Remine can't search for updated time entries, so this method reads last 30 days
        /// </summary>
        /// <returns></returns>
        [HttpPost("ImportTimeEntries/New")]
        public async Task<ApiResponse<ImportStats>> ImportNewTimeEntries()
        {
            DateTime? dateStart = null;

            var cfgMax = _config.GetDateTimeOffset("System:TimeEntryMaxUpdated");

            // Remine can't search for updated time entries, so get ~last month
            if (cfgMax.HasValue)
                dateStart = cfgMax.Value.DateTime.AddDays(-30);

            return await ImportTimeEntries(dateStart, null);
        }

        /// <summary>
        /// Imports time entries for period from Redmine 
        /// </summary>
        /// <param name="dateStart">Day to import time entries from</param>
        /// <param name="dateEnd">Day to import time entries to</param>
        /// <returns></returns>
        [HttpPost("ImportTimeEntries/Custom")]
        public async Task<ApiResponse<ImportStats>> ImportTimeEntries(
            DateTime? dateStart,
            DateTime? dateEnd
            )
        {
            var sw = new Stopwatch();
            sw.Start();
            _logger.LogInformation("Time entries import. Start. "
                + $"{(dateStart.HasValue ? dateStart.Value.ToString("d") : "[ 0 AD ]")} - {(dateEnd.HasValue ? dateEnd.Value.ToString("d") : "[ now ]")}"
                );

            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();

            // init
            var oldMaxDate = _db.TimeEntry.Max(d => (DateTimeOffset?)d.LastReceivedDate) ?? DateTimeOffset.MinValue;

            var result = await _importTimeEntries(dateStart, dateEnd);

            // store remoteMaxUpdated for UpdateNew method
            if (!dateEnd.HasValue)
            {
                var newMaxUpdated = await _db.TimeEntry
                    .Where(d => d.LastReceivedDate > oldMaxDate)
                    .MaxAsync(d => (DateTimeOffset?)d.RedmineUpdated)
                    ;

                DateTimeOffset? cfgMaxUpdated = _config.GetDateTimeOffset("System:TimeEntryMaxUpdated");

                if (newMaxUpdated.HasValue && (!cfgMaxUpdated.HasValue || cfgMaxUpdated < newMaxUpdated))
                    await _config.SetAndSaveAsync("System:TimeEntryMaxUpdated", newMaxUpdated);
            }

            // Find deleted time entries
            {
                var query = _db.TimeEntry
                    .Where(d => !d.IsDeleted)
                    .Where(d => d.LastReceivedDate == null || d.LastReceivedDate <= oldMaxDate)
                    ;

                if (dateStart.HasValue)
                    query = query.Where(d => d.Date >= dateStart);

                if (dateEnd.HasValue)
                    query = query.Where(d => d.Date < dateEnd);

                var list = query.ToList();

                var now = DateTimeOffset.Now;
                foreach (var item in list)
                {
                    item.IsDeleted = true;
                    item.Updated = now;
                }

                await _db.SaveChangesAsync();
                _logger.LogDebug($"Time entries import. {list.Count} marked as deleted.");
            }

            sw.Stop();
            _logger.LogDebug($"Time entries import. Finish. {sw.Elapsed}");

            return ApiResponse.Create(result);
        }

        /// <summary>
        /// Imports issues statuses
        /// </summary>
        /// <returns></returns>
        private async Task<ImportStats> _importIssueStatuses()
        {
            _logger.LogDebug($"Statuses import. Start.");

            using var client = RedmineXmlImporter.CreateWebClient();

            var uri = new Uri($"{_redmineUrl}issue_statuses.json?key={_redmineApiKey}");
            var json = await client.DownloadStringTaskAsync(uri);
            var result = new ImportStats();

            var opts = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };

            var list = JsonSerializer.Deserialize<Models.RedmineJson.IssueStatusResponse>(json, opts);

            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();

            var statuses = _db.IssueStatus.ToList();

            result.total = list.StatusList.Count;
            foreach (var item in list.StatusList)
            {
                var dbItem = statuses.FirstOrDefault(d => d.Id == item.Id);

                if (dbItem == null)
                {
                    dbItem = new Redmine.Models.IssueStatus
                    {
                        Id = item.Id,
                        IsAccepted = false,
                        IsClosed = item.IsClosed,
                        Name = item.Name,
                        Created = DateTimeOffset.Now
                    };
                    await _db.AddAsync(dbItem);
                    result.added++;
                }

                dbItem.RedmineName = item.Name;
                if (_db.Entry(dbItem).State != EntityState.Unchanged)
                {
                    dbItem.Updated = DateTimeOffset.Now;
                    result.updated++;
                }
            }
            await _db.SaveChangesAsync();

            _logger.LogInformation($"Statuses import. Finish. {list.StatusList.Count} processed.");

            return result;
        }

        /// <summary>
        /// Imports issues priorities
        /// </summary>
        /// <returns></returns>
        private async Task<ImportStats> _importIssuePriorities()
        {
            _logger.LogDebug($"Priorities import. Start.");

            using var client = RedmineXmlImporter.CreateWebClient();

            var uri = new Uri($"{_redmineUrl}enumerations/issue_priorities.json?key={_redmineApiKey}");
            var json = await client.DownloadStringTaskAsync(uri);
            var result = new ImportStats();

            var opts = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };

            var list = JsonSerializer.Deserialize<Models.RedmineJson.IssuePriorityResponse>(json, opts);
            // priorities are sorted from lowest to highest
            list.PriorityList.Reverse();

            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();

            var prios = _db.IssuePriority.ToList();

            _logger.LogDebug($"priorities");

            result.total = list.PriorityList.Count;
            foreach (var item in list.PriorityList)
            {
                var dbItem = prios.FirstOrDefault(d => d.Id == item.Id);

                if (dbItem == null)
                {
                    dbItem = new Redmine.Models.IssuePriority
                    {
                        Id = item.Id,
                        Sort = list.PriorityList.IndexOf(item) + 1, // 1 .. 5
                        Created = DateTimeOffset.Now
                    };

                    dbItem.Name = item.Name;

                    var code = $"prio{dbItem.Sort}";
                    if (!prios.Any(d => d.Code == code))
                        dbItem.Code = code;

                    await _db.AddAsync(dbItem);
                    result.added++;
                }

                if (_db.Entry(dbItem).State != EntityState.Unchanged)
                {
                    dbItem.Updated = DateTimeOffset.Now;
                    result.updated++;
                }
            }
            await _db.SaveChangesAsync();

            _logger.LogInformation($"Priorities import. Finish. {list.PriorityList.Count} processed.");

            return result;
        }

        /// <summary>
        /// Imports time entry types
        /// </summary>
        /// <returns></returns>
        private async Task<ImportStats> _importTimeEntryTypes()
        {
            _logger.LogDebug($"Time entry types import. Start.");

            using var client = RedmineXmlImporter.CreateWebClient();

            var uri = new Uri($"{_redmineUrl}enumerations/time_entry_activities.json?key={_redmineApiKey}");
            var json = await client.DownloadStringTaskAsync(uri);
            var result = new ImportStats();

            var opts = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };

            var list = JsonSerializer.Deserialize<Models.RedmineJson.TimeEntryTypeResponse>(json, opts);

            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();

            var types = _db.TimeEntryType.ToList();

            _logger.LogDebug($"time entry types");

            result.total = list.TypeList.Count;
            foreach (var item in list.TypeList)
            {
                var dbItem = types.FirstOrDefault(d => d.Id == item.Id);

                if (dbItem == null)
                {
                    dbItem = new Redmine.Models.TimeEntryType
                    {
                        Id = item.Id,
                        Created = DateTimeOffset.Now
                    };

                    dbItem.Name = item.Name;

                    if (!types.Any(d => d.Code == dbItem.Name))
                        dbItem.Code = dbItem.Name;

                    await _db.AddAsync(dbItem);
                    result.added++;
                }

                if (_db.Entry(dbItem).State != EntityState.Unchanged)
                {
                    dbItem.Updated = DateTimeOffset.Now;
                    result.updated++;
                }
            }
            await _db.SaveChangesAsync();

            _logger.LogInformation($"Time entry types import. Finish. {list.TypeList.Count} processed.");

            return result;
        }

        /// <summary>
        /// Imports custom fields
        /// </summary>
        /// <returns></returns>
        private async Task<ImportStats> _importCustomFields()
        {
            _logger.LogDebug($"Custom fields import. Start.");

            using var client = RedmineXmlImporter.CreateWebClient();

            var uri = new Uri($"{_redmineUrl}custom_fields.json?key={_redmineApiKey}");
            var json = await client.DownloadStringTaskAsync(uri);
            var result = new ImportStats();

            var opts = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };

            var list = JsonSerializer.Deserialize<Models.RedmineJson.CustomFieldResponse>(json, opts);

            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();

            var types = _db.CustomField.ToList();

            result.total = list.FieldList.Count;
            foreach (var item in list.FieldList)
            {
                var dbItem = types.FirstOrDefault(d => d.Id == item.Id);

                if (dbItem == null)
                {
                    dbItem = new Redmine.Models.CustomField
                    {
                        Id = item.Id,
                        Created = DateTimeOffset.Now
                    };

                    await _db.AddAsync(dbItem);
                    result.added++;
                }

                dbItem.Name = item.Name;
                dbItem.Type = item.Type;
                dbItem.Format = item.Format;
                dbItem.IsRequired = item.IsRequired;
                dbItem.IsMultiple = item.IsMultiple;

                if (_db.Entry(dbItem).State != EntityState.Unchanged)
                {
                    dbItem.Updated = DateTimeOffset.Now;
                    result.updated++;
                }
            }
            await _db.SaveChangesAsync();

            _logger.LogInformation($"Custom fields import. Finish. {list.FieldList.Count} processed.");

            return result;
        }

        /// <summary>
        /// Imports issue trackers
        /// </summary>
        /// <returns></returns>
        private async Task<ImportStats> _importIssueTrackers()
        {
            _logger.LogDebug($"Trackers import. Start.");

            using var client = RedmineXmlImporter.CreateWebClient();

            var uri = new Uri($"{_redmineUrl}trackers.json?key={_redmineApiKey}");
            var json = await client.DownloadStringTaskAsync(uri);
            var result = new ImportStats();

            var opts = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };

            var list = JsonSerializer.Deserialize<Models.RedmineJson.TrackerResponse>(json, opts);

            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();

            var trackers = _db.IssueTracker.ToList();

            result.total = list.TrackersList.Count;
            foreach (var item in list.TrackersList)
            {
                var dbItem = trackers.FirstOrDefault(d => d.Id == item.Id);

                if (dbItem == null)
                {
                    dbItem = new Redmine.Models.IssueTracker
                    {
                        Id = item.Id,
                        Created = DateTimeOffset.Now
                    };

                    await _db.AddAsync(dbItem);
                    result.added++;
                }

                dbItem.Name = item.Name;

                if (_db.Entry(dbItem).State != EntityState.Unchanged)
                {
                    dbItem.Updated = DateTimeOffset.Now;
                    result.updated++;
                }
            }
            await _db.SaveChangesAsync();

            _logger.LogInformation($"Trackers import. Finish. {list.TrackersList.Count} processed.");

            return result;
        }

        /// <summary>
        /// Imports users
        /// </summary>
        private async Task<ImportStats> _importUsers(bool IsActive)
        {
            _logger.LogDebug((IsActive ? "Active" : "Blocked") + " users import. Start.");

            var statusId = IsActive ? 1 : 3;

            var uri = $"{_redmineUrl}users.xml?key={_redmineApiKey}&status={statusId}";

            var result = await _doPagedJob(uri, xDoc => _importer.ProcessUsersAsync(xDoc, IsActive));

            _logger.LogInformation((IsActive ? "Active" : "Blocked") + $" users import. Finish. {result.total} received.");

            return result;
        }

        /// <summary>
        /// Imports Projects
        /// </summary>
        /// <returns></returns>
        private async Task<ImportStats> _importProjects()
        {
            _logger.LogDebug("Projects import. Start.");

            var uri = $"{_redmineUrl}projects.xml?key={_redmineApiKey}&include=issue_categories";

            var result = await _doPagedJob(uri, xDoc => _importer.ProcessProjectsAsync(xDoc));

            _logger.LogInformation($"Projects import. Finish. {result.total} received.");

            return result;
        }

        /// <summary>
        /// Imports versions for projects with versions
        /// </summary>
        /// <returns></returns>
        private async Task<ImportStats> _importVersions()
        {
            using var scope = _services.CreateScope();
            using var _db = scope.ServiceProvider.GetRequiredService<DB>();
            var uriList = new List<string>();

            var projects = (
                from d in _db.Project
                select d.Id
                ).ToList()
                ;

            _logger.LogDebug($"Versions import. Start for {projects.Count} projects");

            foreach (var projectId in projects)
                uriList.Add($"{_redmineUrl}projects/{projectId}/versions.xml?key={_redmineApiKey}");

            var result = await _doJob(uriList, xDoc => _importer.ProcessVersionsAsync(xDoc));

            _logger.LogInformation($"Versions import. Finish, {result.total} received for {projects.Count} projects.");

            return result;
        }

        /// <summary>
        /// Imports issue list
        /// </summary>
        private async Task<ImportStats> _importIssueList(DateTime? dateStartUtc, DateTime? dateEndUtc)
        {
            var gte = WebUtility.UrlEncode(">=");
            var lt = WebUtility.UrlEncode("<");

            var processed = 0;

            // prepare url
            var uri = new StringBuilder(
                $"{_redmineUrl}issues.xml" +
                $"?key={_redmineApiKey}" +
                $"&status_id=*" + // without this, only opened tasks are returned
                $"&sort=id" +
                $"&include=relations"
                );

            if (dateStartUtc.HasValue)
                uri.Append($"&updated_on={gte}")
                    .Append(dateStartUtc.Value.ToString("yyyy-MM-ddTHH:mm:ssZ"))
                    ;

            if (dateEndUtc.HasValue)
                uri.Append($"&updated_on={lt}")
                    .Append(dateEndUtc.Value.ToString("yyyy-MM-ddTHH:mm:ssZ"))
                    ;

            var result = await _doPagedJob(uri.ToString(), async xDoc =>
            {
                var counter = await _importer.ProcessIssuesAsync(xDoc);
                var value = Interlocked.Add(ref processed, counter.total);
                if (value % 1000 == 0)
                    _logger.LogDebug($"Issue list import. {value}...");
                return counter;
            });

            // profit
            _logger.LogInformation($"Issue list import. Finish. {result.total} processed.");

            return result;
        }

        /// <summary>
        /// Inports issue details
        /// </summary>
        /// <param name="issueIdList">List of isssue IDs to process</param>
        /// <returns></returns>
        private async Task<ImportStats> _importIssueDetails(List<int> issueIdList)
        {
            _logger.LogInformation($"Issue details import. Start for {issueIdList.Count} item(s).");

            // init
            var uriList = new List<string>();
            var processed = 0;

            foreach (var id in issueIdList)
                uriList.Add(
                    $"{_redmineUrl}issues/{id}.xml" +
                    $"?key={_redmineApiKey}" +
                    $"&include=changesets,journals"
                );

            var result = await _doJob(uriList, async xDoc =>
            {
                var counter = await _importer.ProcessIssueDetailsAsync(xDoc);
                var value = Interlocked.Add(ref processed, counter.total);
                if (value % 1000 == 0)
                    _logger.LogDebug($"Issue details import. {value}...");
                return counter;
            });

            // profit
            _logger.LogInformation($"Issue details import. Finish. {result.total} processed.");

            return result;
        }

        /// <summary>
        /// Imports time entries
        /// </summary>
        private async Task<ImportStats> _importTimeEntries(DateTime? dateStart, DateTime? dateEnd)
        {
            var gte = WebUtility.UrlEncode(">=");
            var lt = WebUtility.UrlEncode("<");

            var processed = 0;

            // prepare url
            var uri = new StringBuilder(
                $"{_redmineUrl}time_entries.xml" +
                $"?key={_redmineApiKey}"
                );

            if (dateStart.HasValue)
                uri.Append($"&from=")
                    .Append(dateStart.Value.ToString("yyyy-MM-dd"))
                    ;

            if (dateEnd.HasValue)
                uri.Append($"&to=")
                    .Append(dateEnd.Value.ToString("yyyy-MM-dd"))
                    ;

            var result = await _doPagedJob(uri.ToString(), async xDoc =>
            {
                var counter = await _importer.ProcessTimeEntriesAsync(xDoc);
                var value = Interlocked.Add(ref processed, counter.total);
                if (value % 5000 == 0)
                    _logger.LogDebug($"Time entries import. {value}...");
                return counter;
            });

            // profit
            _logger.LogInformation($"Time entries import. Finish. {result.total} processed.");

            return result;
        }

        /// <summary>
        /// Gets pages count and starts receiver-processor job for all pages
        /// </summary>
        /// <param name="uri">Base uri to fetch data from</param>
        /// <param name="processor">Processor function for fetched xml</param>
        /// <returns>Child elements in received xml</returns>
        private async Task<ImportStats> _doPagedJob(string uri, Func<XDocument, Task<ImportStats>> processor)
        {
            var pages = await RedmineXmlImporter.GetPageList(uri, _limit);
            var uriList = new List<string>();

            foreach (var page in pages)
            {
                uriList.Add(uri + $"&limit={_limit}&offset={page * _limit}");
            }

            return await _doJob(uriList, processor);
        }

        /// <summary>
        /// Starts received-processor job for passed list of uris
        /// </summary>
        /// <param name="uriList">Uri list to fetch and process</param>
        /// <param name="processor">Processor function for fetched xml</param>
        /// <returns>Child elements in received xml</returns>
        private async Task<ImportStats> _doJob(List<string> uriList, Func<XDocument, Task<ImportStats>> processor)
        {
            var result = new ImportStats();

            var receiveBlock = new TransformBlock<string, XDocument>(
                async (uri) =>
                {
                    XDocument xDoc = null;
                    try
                    {
                        xDoc = await RedmineXmlImporter.ReceiveXmlAsync(uri, 0, 0);
                    }
                    catch (Exception e)
                    {
                        var we = e as WebException;
                        if (we == null)
                            throw;

                        var resp = we.Response as HttpWebResponse;
                        if (resp?.StatusCode != HttpStatusCode.Forbidden)
                            throw;

                        // we've got 403 responsse. It's a project with disabled something.
                    }
                    return xDoc;
                },
                _opts
                );

            var processBlock = new ActionBlock<XDocument>(
                async xDoc =>
                {
                    if (xDoc == null)
                        return;
                    result.Add(await processor(xDoc));
                }
                );

            receiveBlock.LinkTo(processBlock, new DataflowLinkOptions { PropagateCompletion = true });

            foreach (var uri in uriList)
                receiveBlock.Post(uri);

            receiveBlock.Complete();

            await receiveBlock.Completion;
            _logger.LogDebug($"Received all. {processBlock.InputCount} pages waiting for process");
            await processBlock.Completion;

            return result;
        }
    }
}